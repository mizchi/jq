#!/bin/bash
# Verify failing tests against actual jq binary
set -e

check() {
  local filter="$1" input="$2" expected="$3" label="$4"
  local got
  got=$(echo "$input" | jq -c "$filter" 2>&1) || true
  if [ "$got" = "$expected" ]; then
    echo "PASS $label: $filter"
  else
    echo "FAIL $label: $filter"
    echo "  input:    $input"
    echo "  expected: $expected"
    echo "  jq says:  $got"
  fi
}

check '1+1' '"wtasdf"' '2' '#58'
check '.+4' '15' '19' '#61'
check '[range(10)] | .[1.2:3.5]' 'null' '[1,2,3]' '#263'
check '[range(10)] | .[1.5:3.5]' 'null' '[1,2,3]' '#264'
check '[range(10)] | .[1.7:3.5]' 'null' '[1,2,3]' '#265'
check 'try -.? catch .' '"foo"' '"string (\"foo\") cannot be negated"' '#148'
check '[contains(""), contains("\u0000")]' '"\u0000"' '[true,true]' '#135'
check '. - 10' '13911860366432392' '13911860366432382' '#239'
check '[walk(.,1)]' '{"x":0}' '[{"x":0},1]' '#261'
check 'walk(select(IN({}, []) | not))' '{"a":1,"b":{}}' '{"a":1}' '#262'
