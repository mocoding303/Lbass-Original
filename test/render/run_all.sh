#!/bin/bash
# Runs every render suite and reports honestly. Exit codes are checked directly,
# not through a pipeline -- piping to grep made $? report grep's status, which
# once showed two Chromium suites as PASS while they were failing to even load.
cd "$(dirname "$0")/../.." || exit 1
pass=0; fail=0
for t in parse_all test_collection_hero test_eligibility_and_price test_card_matrix \
         test_regression_vs_original test_sale_presentation test_pdp_price test_home_rails; do
  out=$(ruby "test/render/$t.rb" 2>&1); rc=$?
  if [ $rc -eq 0 ]; then printf '%-30s PASS  %s\n' "$t" "$(echo "$out" | grep -v DEPRECATION | tail -1)"; pass=$((pass+1))
  else printf '%-30s FAIL\n' "$t"; echo "$out" | grep -v DEPRECATION | tail -8; fail=$((fail+1)); fi
done
ruby test/render/build_preview.rb >/dev/null 2>&1
ruby test/render/build_pdp_preview.rb >/dev/null 2>&1
for j in test_variant_switch measure_sale; do
  out=$(node "test/render/$j.js" 2>&1); rc=$?
  if [ $rc -eq 0 ]; then printf '%-30s PASS  %s\n' "$j" "$(echo "$out" | grep -v agent-proxy | tail -1)"; pass=$((pass+1))
  else printf '%-30s FAIL\n' "$j"; echo "$out" | grep -v agent-proxy | tail -10; fail=$((fail+1)); fi
done
echo "---- $pass passed, $fail failed"
[ $fail -eq 0 ]
