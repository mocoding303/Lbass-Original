"""Build the -10% genuine-markdown plan from live Admin API data.

Rule, applied in code so it is visible and checkable:
    eligible  =  totalInventory > 0  AND  lbass.promo_eligible is not "false"

compare_at := today's price (genuinely charged for months -> a real former price)
price      := round(today's price * 0.90) to whole dirhams
"""
import json

# handle, product_id, variant_id, price_dh, inventory, promo_eligible
ROWS = [
("new-balance-cargo-pants-sage",15820063899979,57651704693067,549,1,"true"),
("vans-old-skool-black",15820065767755,57651708592459,349,1,"true"),
("adidas-track-pants-black-red",15820066947403,57651711705419,499,1,"true"),
("converse-chuck-70-high-black",15820068356427,57651713245515,499,1,"false"),
("hm-relaxed-cargo-pants-grey",15820069699915,57651715506507,249,1,"true"),
("jordan-23-engineered-pants",15820070879563,57651717800267,599,1,"true"),
("lbass-p001-striped-shirt-shorts-set",15834779648331,57699385246027,349,1,"true"),
("lbass-p002-zara-khaki-jacket",15834779681099,57699385278795,449,1,"false"),
("lbass-p003-nike-calm-flip-flop-beige",15834779713867,57699385311563,549,0,"true"),
("lbass-p004-adidas-black-crossbody-bag",15834779746635,57699385344331,299,1,"true"),
("lbass-p005-nike-black-slides",15834779779403,57699385377099,399,0,"false"),
("lbass-p006-karl-kani-blue-slides",15834779844939,57699385540939,349,1,"true"),
("lbass-p007-new-balance-black-jersey",15834779877707,57699385573707,349,1,"false"),
("lbass-p008-nike-air-black-top",15834779910475,57699385606475,199,1,"true"),
("lbass-p009-nike-black-waist-bag",15834779943243,57699385639243,299,1,"true"),
("lbass-p010a-nike-navy-slides",15834779976011,57699385672011,299,1,"true"),
("lbass-p010b-adidas-black-slides",15834780008779,57699385704779,349,0,"false"),
("lbass-p011-nike-white-cap",15834780041547,57699385737547,349,1,"false"),
("lbass-p012-tommy-hilfiger-black-cap",15834780074315,57699385770315,349,2,"true"),
("uniqlo-beige-open-collar-shirt",15836693201227,57704577466699,299,1,"true"),
("jordan-jumpman-white-t-shirt",15836693233995,57704577499467,249,1,"true"),
("tommy-jeans-black-puffer-jacket",15866231947595,57875362021707,599,1,"false"),
("karl-kani-white-grey-sneakers",15866245316939,57885078421835,499,1,"true"),
("ellesse-black-lightweight-puffer",15866248462667,57875450200395,449,1,"true"),
("nike-green-navy-hooded-puffer",15867750547787,57881858179403,749,0,"true"),
("adidas-black-3-stripes-track-pants",15869116612939,57885049127243,499,0,"false"),
("zara-cream-faux-shearling-biker",15869123068235,57885064429899,549,0,"true"),
("salomon-speedcross-trail-shoes-43",15894102114635,57978738901323,599,1,"true"),
("on-running-white-gold-shoes-43",15894202384715,57978959954251,1199,0,"true"),
("nike-black-tech-joggers-size-l",15894346269003,57979414217035,349,1,"false"),
("carhartt-grey-crossbody-shoulder-bag",15894347514187,57979419197771,300,0,"false"),
("nike-black-tech-joggers-size-l-ar",15894430155083,57979684389195,349,1,"true"),
("on-running-pink-black-shoes-43",15900559180107,58009982370123,900,0,"false"),
("adidas-originals-3-stripes-shorts-xl",15900560195915,58009984467275,249,1,"true"),
("the-north-face-black-puffer-m",15901957587275,58017307885899,749,1,"true"),
("vans-black-white-sneakers-43",15901958734155,58017315193163,449,1,"false"),
("adidas-originals-comic-print-jacket-l",15901959848267,58017322434891,649,1,"true"),
("hugo-white-logo-patch-tshirt-l",15901960241483,58017323254091,249,1,"true"),
("nike-p-6000-silver-43",15901961060683,58017329643851,649,1,"true"),
("adidas-copa-black-football-boots-44",15901961683275,58017332986187,299,1,"false"),
("timberland-black-grey-knit-sneakers",15921151738187,58105880936779,499,1,None),
("adidas-black-blue-turf-football-shoes",15921178575179,58102950003019,299,1,None),
("blue-suede-low-top-sneakers",15921195876683,58105849282891,399,1,None),
("hoka-red-running-shoes",15921651155275,58106036191563,999,1,None),
("nike-air-max-black-green-sneakers",15921652171083,58106041467211,599,1,None),
("adidas-originals-black-trefoil-tank",15921653842251,58106066370891,199,0,None),
("zara-black-shirt-shorts-set",15921656430923,58106081378635,349,1,None),
("tommy-jeans-black-logo-slides",15921657676107,58106099859787,350,0,None),
("adidas-pureboost-white-sneakers-42",15940241129803,58184587215179,550,0,None),
("adidas-originals-black-shorts-l",15940245225803,58184604189003,230,1,None),
("adidas-tiro-sweat-shorts-l",15940420993355,58185686155595,349,1,None),
("adidas-originals-3-stripes-shorts-l",15940422598987,58185688809803,249,0,None),
("pull-bear-blue-distressed-jeans-l",15942017188171,58204685009227,99,0,"false"),
("tommy-hilfiger-white-tshirt-l",15942017253707,58204685074763,249,0,"false"),
("adidas-black-aeroready-shirt-l",15942017286475,58204685107531,230,0,"false"),
("blackhawk-purple-rolltop-backpack",15953856069963,58259104399691,299,1,"false"),
("asics-upcourt-6-white-40",15953856135499,58259104530763,349,1,"false"),
("converse-ctas-ox-black-39-5",15953856168267,58259104563531,249,1,"false"),
("levis-premium-black-paint-jeans-s",15953856201035,58259104596299,149,1,"false"),
("new-rebels-neon-green-rolltop",15953856266571,58259104661835,249,1,"false"),
("aprile-roma-real-leather-handbag",15953856332107,58259104727371,349,1,"false"),
("primark-black-platform-shoes-39",15953856430411,58259104923979,149,1,"false"),
("desigual-floral-crossbody-bag",15953856495947,58259104989515,249,1,"false"),
("zara-black-chunky-boots-39",15953856659787,58259105415499,199,1,"false"),
]

DEPTH = 10

eligible, sold_out, vetoed = [], [], []
for h, pid, vid, dh, inv, promo in ROWS:
    if inv <= 0:
        sold_out.append(h)
    elif promo == "false":
        vetoed.append(h)
    else:
        new_dh = round(dh * (100 - DEPTH) / 100)
        save = dh - new_dh
        # reproduce the theme's half-up per-mille percentage exactly
        pct = ((save * 100 * 1000) // (dh * 100) + 5) // 10
        eligible.append({
            "handle": h, "product_id": pid, "variant_id": vid,
            "was": dh, "now": new_dh, "save": save, "pct": pct,
        })

print(f"ROWS={len(ROWS)}  eligible={len(eligible)}  sold_out={len(sold_out)}  vetoed={len(vetoed)}")
assert len(ROWS) == 64
assert len(eligible) + len(sold_out) + len(vetoed) == 64

base = sum(e["was"] for e in eligible)
give = sum(e["save"] for e in eligible)
print(f"catalogue value {base:,} DH  ·  margin given up {give:,} DH  ·  customers pay {base-give:,} DH")

bad = [e for e in eligible if e["pct"] != DEPTH]
print(f"pieces whose rendered badge would NOT read -{DEPTH}%: {len(bad)}")
for e in bad:
    print(f"   {e['handle']:<40} {e['was']}->{e['now']}  renders -{e['pct']}%")

print()
for e in eligible:
    print(f"  {e['handle']:<40}{e['was']:>6} -> {e['now']:>6} DH   save {e['save']:>4}   -{e['pct']}%")

with open("/tmp/claude-0/-home-user-Lbass-Original/061d3074-3dfd-5128-9d2b-c27ec6905861/scratchpad/eligible.json", "w") as f:
    json.dump(eligible, f, indent=1)
print("\nwrote eligible.json")
