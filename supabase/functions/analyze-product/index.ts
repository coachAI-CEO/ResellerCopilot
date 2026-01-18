import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Ajv from 'https://esm.sh/ajv@8'

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

    let { image_base64, image_url, barcode, store_price, condition } = requestBody || {}
    const itemCondition = condition || 'Used' // Default to 'Used' if not provided

    // If an image_url is provided, fetch the image and convert it to base64
    if (!image_base64 && image_url) {
      try {
        const imgResp = await fetch(image_url)
        if (!imgResp.ok) {
          console.error('Failed to fetch image_url:', image_url, imgResp.status)
        } else {
          const arrayBuffer = await imgResp.arrayBuffer()
          // Convert ArrayBuffer to base64 safely in chunks
          const bytes = new Uint8Array(arrayBuffer)
          let binary = ''
          const chunkSize = 0x8000
          for (let i = 0; i < bytes.length; i += chunkSize) {
            binary += String.fromCharCode(...bytes.subarray(i, i + chunkSize))
          }
          image_base64 = typeof btoa === 'function' ? btoa(binary) : Buffer.from(binary, 'binary').toString('base64')
        }
      } catch (err) {
        console.error('Error fetching/encoding image_url:', err)
      }
    }

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
  // NOTE: Request the model to return ONLY a single JSON object and nothing else to make parsing reliable.
  const systemPrompt = `You are an expert reseller. Analyze this image/barcode. Identify the item. Research and provide detailed pricing information. IMPORTANT: Respond with ONLY a single JSON object (no markdown, no surrounding explanation) with the exact fields requested below. If you cannot provide a field, set it to null.

IMPORTANT: The item condition is "${itemCondition}". Adjust all pricing estimates accordingly:
- "Used": Price should reflect used/opened condition. Look for used item prices on eBay/Amazon.
- "New": Price should reflect new/unopened condition. Look for new item prices.
- "New in Box": Price should reflect new in box (NIB) condition, which often commands a premium over just "New". Look for NIB/BNIB prices.

The condition significantly affects market value - used items are typically 30-50% less than new, while NIB can be 10-20% more than new.
- eBay prices: ALWAYS check current eBay listings and recent sold prices. Provide this number AND the direct URL to the eBay product listing page (ebay_url). The URL should be a full link like "https://www.ebay.com/itm/..." that users can click to view the listing. If you find the price, you MUST try to provide the URL. If no URL can be determined, use null.
- Amazon prices: ALWAYS search for this item on Amazon. Look for current listings, sold prices, and the Buy Box price. If the item exists on Amazon, provide the price AND the direct URL to the Amazon product listing page (amazon_url). The URL should be a full link like "https://www.amazon.com/dp/..." or "https://www.amazon.com/.../dp/..." that users can click to view the product. If you find the price, you MUST try to provide the URL. If no URL can be determined, use null.
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
  "ebay_url": string (CRITICAL: When you provide ebay_price, you MUST also provide the direct URL to the eBay product listing page. Format: "https://www.ebay.com/itm/..." or "https://www.ebay.com/p/...". This URL should be clickable and take users directly to the listing. If you cannot find the URL, use null),
  "amazon_price": number (current Amazon listing price if available),
  "amazon_url": string (CRITICAL: When you provide amazon_price, you MUST also provide the direct URL to the Amazon product listing page. Format: "https://www.amazon.com/dp/..." or "https://www.amazon.com/.../dp/...". This URL should be clickable and take users directly to the product page. If you cannot find the URL, use null),
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
    let analysisResult: any
    try {
      // Try to parse the entire response as JSON first (model instructed to return only JSON)
      analysisResult = JSON.parse(responseText)
    } catch (firstParseError) {
      try {
        // Fallback: extract first JSON substring
        const jsonMatch = responseText.match(/\{[\s\S]*\}/)
        if (jsonMatch) {
          analysisResult = JSON.parse(jsonMatch[0])
        } else {
          throw new Error('No JSON found in response')
        }
      } catch (secondParseError) {
        console.error('Failed to parse Gemini response:', responseText)
        return new Response(
          JSON.stringify({ error: 'Failed to parse AI response', raw_response: responseText }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // Use Ajv to validate the returned JSON against an expected schema
    const ajv = new Ajv()
    const schema = {
      type: 'object',
      properties: {
        verdict: { type: 'string' },
        market_price: { type: 'number' },
        net_profit: { type: 'number' },
        product_name: { type: 'string' },
        velocity_score: { type: 'string' },
        ebay_price: { type: ['number', 'null'] },
        ebay_url: { type: ['string', 'null'] },
        amazon_price: { type: ['number', 'null'] },
        amazon_url: { type: ['string', 'null'] },
  ebay_search_url: { type: ['string', 'null'] },
  amazon_search_url: { type: ['string', 'null'] },
        current_price: { type: ['number', 'null'] },
        market_price_source: { type: ['string', 'null'] },
        sales_tax_rate: { type: ['number', 'null'] },
        sales_tax_amount: { type: ['number', 'null'] },
        fee_percentage: { type: ['number', 'null'] },
        fees_amount: { type: ['number', 'null'] },
        shipping_cost: { type: ['number', 'null'] },
        profit_calculation: { type: ['string', 'null'] },
        market_analysis: { type: ['string', 'null'] },
        product_image_url: { type: ['string', 'null'] },
      },
      required: ['verdict', 'market_price', 'net_profit', 'product_name', 'velocity_score'],
      additionalProperties: true,
    }

    const validate = ajv.compile(schema)
    const valid = validate(analysisResult)
    if (!valid) {
      console.error('Ajv validation errors:', validate.errors)
      return new Response(
        JSON.stringify({ error: 'Invalid AI response schema', details: validate.errors, raw_response: responseText }),
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
    const ebayUrl = analysisResult.ebay_url || null
    const amazonPrice = analysisResult.amazon_price ? parseFloat(analysisResult.amazon_price) : null
    const amazonUrl = analysisResult.amazon_url || null
    const currentPrice = analysisResult.current_price ? parseFloat(analysisResult.current_price) : null
    
      // Helper to validate that a marketplace URL actually resolves (not 404).
      // Uses a GET request with a common User-Agent to reduce chance of bot blocking.
      async function validateUrl(url: string | null) {
        if (!url) return null
        try {
          const resp = await fetch(url, {
            method: 'GET',
            headers: {
              'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            },
          })
          // Treat 2xx and 3xx as valid (followed redirects ok)
          if (resp && resp.status >= 200 && resp.status < 400) {
            return url
          }
          console.warn('validateUrl: non-OK status', { url, status: resp.status })
          return null
        } catch (err) {
          console.warn('validateUrl error for', url, err)
          return null
        }
      }
    const marketPriceSource = analysisResult.market_price_source || 'Market analysis'
    const salesTaxRate = analysisResult.sales_tax_rate ? parseFloat(analysisResult.sales_tax_rate) : 8
    const salesTaxAmount = analysisResult.sales_tax_amount ? parseFloat(analysisResult.sales_tax_amount) : (store_price * salesTaxRate / 100)
    const feePercentage = analysisResult.fee_percentage ? parseFloat(analysisResult.fee_percentage) : 15
    const feesAmount = analysisResult.fees_amount ? parseFloat(analysisResult.fees_amount) : (marketPrice * 0.15)
    const shippingCost = analysisResult.shipping_cost ? parseFloat(analysisResult.shipping_cost) : null
    const profitCalculation = analysisResult.profit_calculation || 
      `$${marketPrice.toFixed(2)} market price - $${store_price.toFixed(2)} buy price - $${salesTaxAmount.toFixed(2)} sales tax (${salesTaxRate}%) - $${feesAmount.toFixed(2)} fees (${feePercentage}%)${shippingCost ? ` - $${shippingCost.toFixed(2)} shipping` : ''} = $${netProfit.toFixed(2)} profit`

    // Validate marketplace URLs and prepare helpful search fallbacks
    const validEbayUrl = await validateUrl(ebayUrl)
    const validAmazonUrl = await validateUrl(amazonUrl)

    // Fallback search URLs (useful if the AI-provided direct link is dead)
    const ebaySearchUrl = `https://www.ebay.com/sch/i.html?_nkw=${encodeURIComponent(productName)}`
    const amazonSearchUrl = `https://www.amazon.com/s?k=${encodeURIComponent(productName)}`

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
          ebay_url: validEbayUrl,
          ebay_search_url: validEbayUrl ? null : ebaySearchUrl,
        amazon_price: amazonPrice,
          amazon_url: validAmazonUrl,
          amazon_search_url: validAmazonUrl ? null : amazonSearchUrl,
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
