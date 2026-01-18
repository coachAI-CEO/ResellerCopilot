import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    })
  }

  console.log('Request received:', { method: req.method, url: req.url })
  
  try {
    // Get the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client with the authorization header
    // Supabase automatically provides these environment variables
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || Deno.env.get('SUPABASE_PROJECT_URL') || ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') || ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    
    console.log('Supabase URL:', supabaseUrl ? 'Set' : 'Missing')
    console.log('Supabase Anon Key:', supabaseAnonKey ? 'Set' : 'Missing')
    console.log('Supabase Service Key:', supabaseServiceKey ? 'Set' : 'Not set (using anon key)')
    
    if (!supabaseUrl || !supabaseAnonKey) {
      console.error('Missing Supabase configuration', { supabaseUrl: !!supabaseUrl, supabaseAnonKey: !!supabaseAnonKey })
      return new Response(
        JSON.stringify({ error: 'Server configuration error: Missing Supabase credentials' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Ensure Authorization header has Bearer prefix
    const bearerToken = authHeader.startsWith('Bearer ') 
      ? authHeader 
      : `Bearer ${authHeader}`

    // Create Supabase client - use service role key if available, otherwise use anon key
    // Service role key can verify user tokens more reliably
    const clientKey = supabaseServiceKey || supabaseAnonKey
    
    const supabaseClient = createClient(supabaseUrl, clientKey, {
      global: {
        headers: { Authorization: bearerToken },
      },
    })

    // Verify the user is authenticated by getting the user
    let user = null
    let userError = null
    
    try {
      const userResult = await supabaseClient.auth.getUser()
      user = userResult.data?.user
      userError = userResult.error
      
      if (userError) {
        console.error('getUser() error:', userError)
        // If using anon key and getUser fails, try alternative verification
        if (!supabaseServiceKey) {
          // Try to get session as fallback
          const sessionResult = await supabaseClient.auth.getSession()
          if (sessionResult.data?.session?.user) {
            user = sessionResult.data.session.user
            userError = null
          }
        }
      }
    } catch (err) {
      console.error('Exception in getUser():', err)
      userError = { message: err?.message || 'Authentication failed', status: 401 }
    }

    if (userError || !user) {
      console.error('Authentication failed:', userError || 'No user found')
      return new Response(
        JSON.stringify({ 
          error: 'Unauthorized', 
          details: userError?.message || 'Invalid or expired JWT token. Please log in again.',
          code: 401
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    let requestBody
    try {
      requestBody = await req.json()
    } catch (parseError) {
      console.error('Failed to parse request body:', parseError)
      return new Response(
        JSON.stringify({ error: 'Invalid request body', details: parseError?.message }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { image_base64, barcode, store_price, condition } = requestBody || {}
    const itemCondition = condition || 'Used' // Default to 'Used' if not provided

    if (!GEMINI_API_KEY) {
      return new Response(
        JSON.stringify({ error: 'Gemini API key not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!store_price || store_price <= 0) {
      return new Response(
        JSON.stringify({ error: 'Valid store_price is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Prepare the system prompt
    const systemPrompt = `You are an expert reseller. Analyze this image/barcode. Identify the item. Research and provide detailed pricing information:

IMPORTANT: The item condition is "${itemCondition}". Adjust all pricing estimates accordingly:
- "Used": Price should reflect used/opened condition. Look for used item prices on eBay/Amazon.
- "New": Price should reflect new/unopened condition. Look for new item prices.
- "New in Box": Price should reflect new in box (NIB) condition, which often commands a premium over just "New". Look for NIB/BNIB prices.

The condition significantly affects market value - used items are typically 30-50% less than new, while NIB can be 10-20% more than new.
- eBay prices: ALWAYS check current eBay listings and recent sold prices. Provide this number. Also extract the main product image URL from eBay listings if available.
- Amazon prices: ALWAYS search for this item on Amazon. Look for current listings, sold prices, and the Buy Box price. If the item exists on Amazon, provide the price and extract the main product image URL. If not available or out of stock, explicitly note this but still try to estimate based on similar items or historical data.
- Current market price: The best estimate of what this item sells for currently
- Market price source: Specify where you found the market price (e.g., "eBay sold listings average", "Amazon current listings", "Average of eBay and Amazon sold prices")

IMPORTANT: Always provide both ebay_price and amazon_price in your response. If you cannot find Amazon pricing, provide your best estimate based on similar items or historical data, or use null/0 if truly unavailable.

Velocity Score (How quickly this item sells):
- "High" velocity: Item sells very quickly (within days/weeks). Look for: many recent sold listings, consistent demand, trending/branded items, popular categories. These are fast-moving items that turn inventory quickly.
- "Med" velocity: Item sells at moderate pace (weeks to months). Look for: some recent sold listings, steady but not rapid demand. These items will sell but may take some time.
- "Low" velocity: Item sells slowly (months+). Look for: few/no recent sold listings, niche items, seasonal items out of season, specialty items with limited market. These items tie up capital longer.

Assess velocity based on: number of recent sold listings on eBay/Amazon, time between listings and sales, market demand indicators, category popularity, and brand recognition. 

Calculate profit with detailed breakdown:
- Sales tax: Estimate 7-10% of buy price (typical US sales tax rate, adjust based on location if known)
- Standard reseller fees: 15% of market price (this includes platform fees like eBay's ~13% + PayPal fees, or Amazon's ~15% referral fee)
- Shipping cost: Estimate $5-10 for typical items (adjust based on item size/weight if visible in image)
- Total buy cost = Buy Price + Sales Tax
- Net profit = Market Price - Total Buy Cost - Fees (15% of market price) - Shipping Cost

Return JSON with these exact fields:
{
  "verdict": "BUY" or "PASS",
  "market_price": number (ESTIMATED SELLING PRICE - what you can realistically sell for, based on recent COMPLETED/SOLD listings, NOT asking prices. This is the key number for profit calculation),
  "ebay_price": number (current eBay listing price or average of recent sold listings - specify which),
  "amazon_price": number (current Amazon listing price if available),
  "current_price": number (lowest current listing price across platforms - what you could buy it for right now, useful for market context),
  "market_price_source": string (explanation of where market_price comes from, e.g., "Average of 5 recent eBay sold listings", "Amazon sold listings average", "Average of recent eBay and Amazon completed sales"),
  "net_profit": number (calculated as: market_price - store_price - sales_tax - fees - shipping),
  "sales_tax_rate": number (estimated sales tax rate, typically 7-10%),
  "sales_tax_amount": number (calculated as: store_price * sales_tax_rate / 100),
  "fee_percentage": number (15, representing 15% platform fees),
  "fees_amount": number (calculated as: market_price * 0.15),
  "shipping_cost": number (estimated shipping cost, typically 5-10),
  "profit_calculation": string (human-readable breakdown, e.g., "$80 market price - $9.99 buy price - $0.70 sales tax (7%) - $12 fees (15%) - $7 shipping = $50.31 profit"),
  "reasoning": string,
  "velocity_score": "High" or "Med" or "Low",
  "product_name": string,
  "product_image_url": string (CRITICAL: Provide a direct image URL of the actual product from eBay, Amazon, or other marketplace listings. This should be the product's official image from online listings, NOT the scanned photo. Look for product images in the listings you're analyzing. The URL should be a direct image link (ending in .jpg, .png, etc.) that can be displayed. If you cannot find a product image URL, use null),
  "market_analysis": string (comprehensive market analysis in the following format:

"Market Analysis
The Item: [Full product name and model/sku if available]

Why it's good: [Explain brand value, collaborations, collector appeal, hype factors, target audience, why resellers/collectors want this]

Scarcity: [Availability status - sold out? Limited release? Common? How availability affects price]

The Data:
eBay: [Active listings, recent sold prices, price range]
Amazon: [If available - listings and prices]
StockX/Other Platforms: [If relevant - sales history, price ranges]
Other Market Data: [Any other relevant pricing data]

The Buy Cost: [Analyze the buy price vs retail/market value. Calculate percentage. Explain if this is a good deal - 'Golden Ratio' if paying low percentage of retail]

Strategy:
Where to List: [Best platforms - eBay, Amazon, Grailed, StockX, Facebook Marketplace, etc. and why]
Keywords: [Important keywords/tags to include in listing title]
Pricing: [Recommended listing price, best offer strategy, lowest acceptable price]
Additional Tips: [Any other selling strategy advice]

Warnings: [Condition issues to check, common problems, things to inspect, buyer expectations]

Summary: [Final verdict - best item? Good buy? Pass? Action recommendation]"`

    // Build the Gemini API request
    const geminiPayload: any = {
      contents: [{
        parts: [
          { text: systemPrompt },
        ],
      }],
    }

    // Add image if provided
    if (image_base64) {
      geminiPayload.contents[0].parts.push({
        inline_data: {
          mime_type: 'image/jpeg',
          data: image_base64,
        },
      })
    }

    // Add barcode context if provided
    if (barcode) {
      geminiPayload.contents[0].parts.push({
        text: `Barcode: ${barcode}`,
      })
    }

    // Add store price and condition context
    geminiPayload.contents[0].parts.push({
      text: `Store Price: $${store_price.toFixed(2)}\nItem Condition: ${itemCondition}`,
    })

    // Call Gemini API
    console.log('Calling Gemini API...', { 
      url: GEMINI_API_URL,
      hasImage: !!image_base64,
      hasBarcode: !!barcode,
      storePrice: store_price
    })
    
    const geminiResponse = await fetch(
      `${GEMINI_API_URL}?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(geminiPayload),
      }
    )
    
    console.log('Gemini API response status:', geminiResponse.status)

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text()
      console.error('Gemini API error:', errorText)
      let errorDetails = 'Failed to analyze product with AI'
      try {
        const errorJson = JSON.parse(errorText)
        errorDetails = errorJson.error?.message || errorJson.message || errorText
      } catch {
        errorDetails = errorText || 'Unknown Gemini API error'
      }
      return new Response(
        JSON.stringify({ 
          error: 'Failed to analyze product with AI',
          details: errorDetails,
          status: geminiResponse.status
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const geminiData = await geminiResponse.json()
    const responseText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text

    if (!responseText) {
      return new Response(
        JSON.stringify({ error: 'No response from AI' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse the JSON response from Gemini
    let analysisResult
    try {
      // Extract JSON from the response (in case it's wrapped in markdown or text)
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      if (jsonMatch) {
        analysisResult = JSON.parse(jsonMatch[0])
      } else {
        throw new Error('No JSON found in response')
      }
    } catch (parseError) {
      console.error('Failed to parse Gemini response:', responseText)
      return new Response(
        JSON.stringify({ error: 'Failed to parse AI response', raw_response: responseText }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate and normalize the response
    const verdict = analysisResult.verdict?.toUpperCase() === 'BUY' ? 'BUY' : 'PASS'
    const marketPrice = parseFloat(analysisResult.market_price) || 0
    const netProfit = parseFloat(analysisResult.net_profit) || 0
    const velocityScore = ['High', 'Med', 'Low'].includes(analysisResult.velocityScore) 
      ? analysisResult.velocityScore 
      : 'Med'
    const productName = analysisResult.product_name || 'Unknown Product'
    const reasoning = analysisResult.reasoning || 'No reasoning provided'
    const marketAnalysis = analysisResult.market_analysis || null
    const productImageUrl = analysisResult.product_image_url || null
    const ebayPrice = analysisResult.ebay_price ? parseFloat(analysisResult.ebay_price) : null
    const amazonPrice = analysisResult.amazon_price ? parseFloat(analysisResult.amazon_price) : null
    const currentPrice = analysisResult.current_price ? parseFloat(analysisResult.current_price) : null
    const marketPriceSource = analysisResult.market_price_source || 'Market analysis'
    const salesTaxRate = analysisResult.sales_tax_rate ? parseFloat(analysisResult.sales_tax_rate) : 8
    const salesTaxAmount = analysisResult.sales_tax_amount ? parseFloat(analysisResult.sales_tax_amount) : (store_price * salesTaxRate / 100)
    const feePercentage = analysisResult.fee_percentage ? parseFloat(analysisResult.fee_percentage) : 15
    const feesAmount = analysisResult.fees_amount ? parseFloat(analysisResult.fees_amount) : (marketPrice * 0.15)
    const shippingCost = analysisResult.shipping_cost ? parseFloat(analysisResult.shipping_cost) : null
    const profitCalculation = analysisResult.profit_calculation || 
      `$${marketPrice.toFixed(2)} market price - $${store_price.toFixed(2)} buy price - $${salesTaxAmount.toFixed(2)} sales tax (${salesTaxRate}%) - $${feesAmount.toFixed(2)} fees (${feePercentage}%)${shippingCost ? ` - $${shippingCost.toFixed(2)} shipping` : ''} = $${netProfit.toFixed(2)} profit`

    // Return the analysis result
    return new Response(
      JSON.stringify({
        verdict,
        market_price: marketPrice,
        net_profit: netProfit,
        reasoning,
        velocity_score: velocityScore,
        product_name: productName,
        ebay_price: ebayPrice,
        amazon_price: amazonPrice,
        current_price: currentPrice,
        market_price_source: marketPriceSource,
        sales_tax_rate: salesTaxRate,
        sales_tax_amount: salesTaxAmount,
        fee_percentage: feePercentage,
        fees_amount: feesAmount,
        shipping_cost: shippingCost,
        profit_calculation: profitCalculation,
        market_analysis: marketAnalysis,
        product_image_url: productImageUrl,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('Error in analyze-product function:', error)
    const errorMessage = error instanceof Error ? error.message : String(error)
    const errorStack = error instanceof Error ? error.stack : undefined
    console.error('Error stack:', errorStack)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        details: errorMessage,
        ...(process.env.NODE_ENV === 'development' && errorStack ? { stack: errorStack } : {})
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
