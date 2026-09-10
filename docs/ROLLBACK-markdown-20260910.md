# Rollback — undo the 2026-09-10 −10% markdown

Restores all 31 pieces to their pre-markdown price and clears `compare_at_price`,
which removes every strikethrough, percentage pill and «وفّر» line from the site.

Run in Shopify Admin → Apps → **Shopify GraphiQL App**, or via any Admin API
client. Split into two documents purely to stay inside the API cost limit.

Verify afterwards by confirming `compareAtPrice` is `null` on all 31.

## Document A (16 pieces)

```graphql
mutation RollbackA {
  m0: productVariantsBulkUpdate(productId: "gid://shopify/Product/15820063899979", variants: [{id: "gid://shopify/ProductVariant/57651704693067", price: "549.00", compareAtPrice: null}]) { userErrors { field message } }   # new-balance-cargo-pants-sage  494 -> 549
  m1: productVariantsBulkUpdate(productId: "gid://shopify/Product/15820065767755", variants: [{id: "gid://shopify/ProductVariant/57651708592459", price: "349.00", compareAtPrice: null}]) { userErrors { field message } }   # vans-old-skool-black  314 -> 349
  m2: productVariantsBulkUpdate(productId: "gid://shopify/Product/15820066947403", variants: [{id: "gid://shopify/ProductVariant/57651711705419", price: "499.00", compareAtPrice: null}]) { userErrors { field message } }   # adidas-track-pants-black-red  449 -> 499
  m3: productVariantsBulkUpdate(productId: "gid://shopify/Product/15820069699915", variants: [{id: "gid://shopify/ProductVariant/57651715506507", price: "249.00", compareAtPrice: null}]) { userErrors { field message } }   # hm-relaxed-cargo-pants-grey  224 -> 249
  m4: productVariantsBulkUpdate(productId: "gid://shopify/Product/15820070879563", variants: [{id: "gid://shopify/ProductVariant/57651717800267", price: "599.00", compareAtPrice: null}]) { userErrors { field message } }   # jordan-23-engineered-pants  539 -> 599
  m5: productVariantsBulkUpdate(productId: "gid://shopify/Product/15834779648331", variants: [{id: "gid://shopify/ProductVariant/57699385246027", price: "349.00", compareAtPrice: null}]) { userErrors { field message } }   # lbass-p001-striped-shirt-shorts-set  314 -> 349
  m6: productVariantsBulkUpdate(productId: "gid://shopify/Product/15834779746635", variants: [{id: "gid://shopify/ProductVariant/57699385344331", price: "299.00", compareAtPrice: null}]) { userErrors { field message } }   # lbass-p004-adidas-black-crossbody-bag  269 -> 299
  m7: productVariantsBulkUpdate(productId: "gid://shopify/Product/15834779844939", variants: [{id: "gid://shopify/ProductVariant/57699385540939", price: "349.00", compareAtPrice: null}]) { userErrors { field message } }   # lbass-p006-karl-kani-blue-slides  314 -> 349
  m8: productVariantsBulkUpdate(productId: "gid://shopify/Product/15834779910475", variants: [{id: "gid://shopify/ProductVariant/57699385606475", price: "199.00", compareAtPrice: null}]) { userErrors { field message } }   # lbass-p008-nike-air-black-top  179 -> 199
  m9: productVariantsBulkUpdate(productId: "gid://shopify/Product/15834779943243", variants: [{id: "gid://shopify/ProductVariant/57699385639243", price: "299.00", compareAtPrice: null}]) { userErrors { field message } }   # lbass-p009-nike-black-waist-bag  269 -> 299
  m10: productVariantsBulkUpdate(productId: "gid://shopify/Product/15834779976011", variants: [{id: "gid://shopify/ProductVariant/57699385672011", price: "299.00", compareAtPrice: null}]) { userErrors { field message } }   # lbass-p010a-nike-navy-slides  269 -> 299
  m11: productVariantsBulkUpdate(productId: "gid://shopify/Product/15834780074315", variants: [{id: "gid://shopify/ProductVariant/57699385770315", price: "349.00", compareAtPrice: null}]) { userErrors { field message } }   # lbass-p012-tommy-hilfiger-black-cap  314 -> 349
  m12: productVariantsBulkUpdate(productId: "gid://shopify/Product/15836693201227", variants: [{id: "gid://shopify/ProductVariant/57704577466699", price: "299.00", compareAtPrice: null}]) { userErrors { field message } }   # uniqlo-beige-open-collar-shirt  269 -> 299
  m13: productVariantsBulkUpdate(productId: "gid://shopify/Product/15836693233995", variants: [{id: "gid://shopify/ProductVariant/57704577499467", price: "249.00", compareAtPrice: null}]) { userErrors { field message } }   # jordan-jumpman-white-t-shirt  224 -> 249
  m14: productVariantsBulkUpdate(productId: "gid://shopify/Product/15866245316939", variants: [{id: "gid://shopify/ProductVariant/57885078421835", price: "499.00", compareAtPrice: null}]) { userErrors { field message } }   # karl-kani-white-grey-sneakers  449 -> 499
  m15: productVariantsBulkUpdate(productId: "gid://shopify/Product/15866248462667", variants: [{id: "gid://shopify/ProductVariant/57875450200395", price: "449.00", compareAtPrice: null}]) { userErrors { field message } }   # ellesse-black-lightweight-puffer  404 -> 449
}
```

## Document B (15 pieces)

```graphql
mutation RollbackB {
  m0: productVariantsBulkUpdate(productId: "gid://shopify/Product/15894102114635", variants: [{id: "gid://shopify/ProductVariant/57978738901323", price: "599.00", compareAtPrice: null}]) { userErrors { field message } }   # salomon-speedcross-trail-shoes-43  539 -> 599
  m1: productVariantsBulkUpdate(productId: "gid://shopify/Product/15894430155083", variants: [{id: "gid://shopify/ProductVariant/57979684389195", price: "349.00", compareAtPrice: null}]) { userErrors { field message } }   # nike-black-tech-joggers-size-l-ar  314 -> 349
  m2: productVariantsBulkUpdate(productId: "gid://shopify/Product/15900560195915", variants: [{id: "gid://shopify/ProductVariant/58009984467275", price: "249.00", compareAtPrice: null}]) { userErrors { field message } }   # adidas-originals-3-stripes-shorts-xl  224 -> 249
  m3: productVariantsBulkUpdate(productId: "gid://shopify/Product/15901957587275", variants: [{id: "gid://shopify/ProductVariant/58017307885899", price: "749.00", compareAtPrice: null}]) { userErrors { field message } }   # the-north-face-black-puffer-m  674 -> 749
  m4: productVariantsBulkUpdate(productId: "gid://shopify/Product/15901959848267", variants: [{id: "gid://shopify/ProductVariant/58017322434891", price: "649.00", compareAtPrice: null}]) { userErrors { field message } }   # adidas-originals-comic-print-jacket-l  584 -> 649
  m5: productVariantsBulkUpdate(productId: "gid://shopify/Product/15901960241483", variants: [{id: "gid://shopify/ProductVariant/58017323254091", price: "249.00", compareAtPrice: null}]) { userErrors { field message } }   # hugo-white-logo-patch-tshirt-l  224 -> 249
  m6: productVariantsBulkUpdate(productId: "gid://shopify/Product/15901961060683", variants: [{id: "gid://shopify/ProductVariant/58017329643851", price: "649.00", compareAtPrice: null}]) { userErrors { field message } }   # nike-p-6000-silver-43  584 -> 649
  m7: productVariantsBulkUpdate(productId: "gid://shopify/Product/15921151738187", variants: [{id: "gid://shopify/ProductVariant/58105880936779", price: "499.00", compareAtPrice: null}]) { userErrors { field message } }   # timberland-black-grey-knit-sneakers  449 -> 499
  m8: productVariantsBulkUpdate(productId: "gid://shopify/Product/15921178575179", variants: [{id: "gid://shopify/ProductVariant/58102950003019", price: "299.00", compareAtPrice: null}]) { userErrors { field message } }   # adidas-black-blue-turf-football-shoes  269 -> 299
  m9: productVariantsBulkUpdate(productId: "gid://shopify/Product/15921195876683", variants: [{id: "gid://shopify/ProductVariant/58105849282891", price: "399.00", compareAtPrice: null}]) { userErrors { field message } }   # blue-suede-low-top-sneakers  359 -> 399
  m10: productVariantsBulkUpdate(productId: "gid://shopify/Product/15921651155275", variants: [{id: "gid://shopify/ProductVariant/58106036191563", price: "999.00", compareAtPrice: null}]) { userErrors { field message } }   # hoka-red-running-shoes  899 -> 999
  m11: productVariantsBulkUpdate(productId: "gid://shopify/Product/15921652171083", variants: [{id: "gid://shopify/ProductVariant/58106041467211", price: "599.00", compareAtPrice: null}]) { userErrors { field message } }   # nike-air-max-black-green-sneakers  539 -> 599
  m12: productVariantsBulkUpdate(productId: "gid://shopify/Product/15921656430923", variants: [{id: "gid://shopify/ProductVariant/58106081378635", price: "349.00", compareAtPrice: null}]) { userErrors { field message } }   # zara-black-shirt-shorts-set  314 -> 349
  m13: productVariantsBulkUpdate(productId: "gid://shopify/Product/15940245225803", variants: [{id: "gid://shopify/ProductVariant/58184604189003", price: "230.00", compareAtPrice: null}]) { userErrors { field message } }   # adidas-originals-black-shorts-l  207 -> 230
  m14: productVariantsBulkUpdate(productId: "gid://shopify/Product/15940420993355", variants: [{id: "gid://shopify/ProductVariant/58185686155595", price: "349.00", compareAtPrice: null}]) { userErrors { field message } }   # adidas-tiro-sweat-shorts-l  314 -> 349
}
```
