///|
fn run_jq(filter : String, input : String) -> Array[String] {
  @jq.run_string(filter, input) catch {
    @jq.JqError::JqError(msg) => ["ERROR: " + msg]
  }
}

///|
test "jq_compat_1: true" {
  inspect(
    run_jq("true", "null"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_2: false" {
  inspect(
    run_jq("false", "null"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_3: null" {
  inspect(
    run_jq("null", "42"),
    content=(
      #|["null"]
    ),
  )
}

///|
test "jq_compat_4: 1" {
  inspect(
    run_jq("1", "null"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_5: -1" {
  inspect(
    run_jq("-1", "null"),
    content=(
      #|["-1"]
    ),
  )
}

///|
test "jq_compat_6: {}" {
  inspect(
    run_jq("{}", "null"),
    content=(
      #|["{}"]
    ),
  )
}

///|
test "jq_compat_7: []" {
  inspect(
    run_jq("[]", "null"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_8: {x:-1},{x:-.},{x:-.|abs}" {
  inspect(
    run_jq("{x:-1},{x:-.},{x:-.|abs}", "1"),
    content=(
      #|["{\"x\":-1}", "{\"x\":-1}", "{\"x\":1}"]
    ),
  )
}

///|
test "jq_compat_9: \"Aa\\r\\n\\t\\b\\f\\u03bc\"" {
  inspect(
    run_jq("\"Aa\\r\\n\\t\\b\\f\\u03bc\"", "null"),
    content=(
      #|["\"Aa\\r\\n\\t\\\\b\\\\f\\\\u03bc\""]
    ),
  )
}

///|
test "jq_compat_10: ." {
  inspect(
    run_jq(".", "\"Aa\\r\\n\\t\\b\\f\\u03bc\""),
    content=(
      #|["\"Aa\\r\\n\\t\\b\\fμ\""]
    ),
  )
}

///|
test "jq_compat_11: \"inter\\(\"pol\" + \"ation\")\"" {
  inspect(
    run_jq("\"inter\\(\"pol\" + \"ation\")\"", "null"),
    content=(
      #|["\"interpolation\""]
    ),
  )
}

///|
test "jq_compat_12: @base64" {
  inspect(
    run_jq("@base64", "\"foóbar\\n\""),
    content=(
      #|["\"Zm/Ds2Jhcgo=\""]
    ),
  )
}

///|
test "jq_compat_13: @base64d" {
  inspect(
    run_jq("@base64d", "\"Zm/Ds2Jhcgo=\""),
    content=(
      #|["\"foóbar\\n\""]
    ),
  )
}

///|
test "jq_compat_14: @uri" {
  inspect(
    run_jq("@uri", "\"\\u03bc\""),
    content=(
      #|["\"%CE%BC\""]
    ),
  )
}

///|
test "jq_compat_15: @html \"<b>\\(.)</b>\"" {
  inspect(
    run_jq("@html \"<b>\\(.)</b>\"", "\"<script>hax</script>\""),
    content=(
      #|["ERROR: unexpected token: StrInterp([Lit(\"<b>\"), ExprSource(\".\"), Lit(\"</b>\")])"]
    ),
  )
}

///|
test "jq_compat_16: [.[]|tojson|fromjson]" {
  inspect(
    run_jq(
      "[.[]|tojson|fromjson]", "[\"foo\", 1, [\"a\", 1, \"b\", 2, {\"foo\":\"bar\"}]]",
    ),
    content=(
      #|["[\"foo\",1,[\"a\",1,\"b\",2,{\"foo\":\"bar\"}]]"]
    ),
  )
}

///|
test "jq_compat_17: {a: 1}" {
  inspect(
    run_jq("{a: 1}", "null"),
    content=(
      #|["{\"a\":1}"]
    ),
  )
}

///|
test "jq_compat_18: {a,b,(.d):.a,e:.b}" {
  inspect(
    run_jq("{a,b,(.d):.a,e:.b}", "{\"a\":1, \"b\":2, \"c\":3, \"d\":\"c\"}"),
    content=(
      #|["{\"a\":1,\"b\":2,\"c\":1,\"e\":2}"]
    ),
  )
}

///|
test "jq_compat_19: {\"a\",b,\"a$\\(1+1)\"}" {
  inspect(
    run_jq("{\"a\",b,\"a$\\(1+1)\"}", "{\"a\":1, \"b\":2, \"c\":3, \"a$2\":4}"),
    content=(
      #|["{\"a\":1,\"b\":2,\"a$2\":4}"]
    ),
  )
}

///|
test "jq_compat_20: .foo" {
  inspect(
    run_jq(".foo", "{\"foo\": 42, \"bar\": 43}"),
    content=(
      #|["42"]
    ),
  )
}

///|
test "jq_compat_21: .foo | .bar" {
  inspect(
    run_jq(".foo | .bar", "{\"foo\": {\"bar\": 42}, \"bar\": \"badvalue\"}"),
    content=(
      #|["42"]
    ),
  )
}

///|
test "jq_compat_22: .foo.bar" {
  inspect(
    run_jq(".foo.bar", "{\"foo\": {\"bar\": 42}, \"bar\": \"badvalue\"}"),
    content=(
      #|["42"]
    ),
  )
}

///|
test "jq_compat_23: .foo_bar" {
  inspect(
    run_jq(".foo_bar", "{\"foo_bar\": 2}"),
    content=(
      #|["2"]
    ),
  )
}

///|
test "jq_compat_24: .[\"foo\"].bar" {
  inspect(
    run_jq(".[\"foo\"].bar", "{\"foo\": {\"bar\": 42}, \"bar\": \"badvalue\"}"),
    content=(
      #|["42"]
    ),
  )
}

///|
test "jq_compat_25: .\"foo\".\"bar\"" {
  inspect(
    run_jq(".\"foo\".\"bar\"", "{\"foo\": {\"bar\": 20}}"),
    content=(
      #|["20"]
    ),
  )
}

///|
test "jq_compat_26: [.[]|.foo?]" {
  inspect(
    run_jq("[.[]|.foo?]", "[1,[2],{\"foo\":3,\"bar\":4},{},{\"foo\":5}]"),
    content=(
      #|["[3,null,5]"]
    ),
  )
}

///|
test "jq_compat_27: [.[]|.foo?.bar?]" {
  inspect(
    run_jq(
      "[.[]|.foo?.bar?]", "[1,[2],[],{\"foo\":3},{\"foo\":{\"bar\":4}},{}]",
    ),
    content=(
      #|["[4,null]"]
    ),
  )
}

///|
test "jq_compat_28: [..]" {
  inspect(
    run_jq("[..]", "[1,[[2]],{ \"a\":[1]}]"),
    content=(
      #|["[[1,[[2]],{\"a\":[1]}],1,[[2]],[2],2,{\"a\":[1]},[1],1]"]
    ),
  )
}

///|
test "jq_compat_29: [.[]|.[1:3]?]" {
  inspect(
    run_jq(
      "[.[]|.[1:3]?]", "[1,null,true,false,\"abcdef\",{},{\"a\":1,\"b\":2},[],[1,2,3,4,5],[1,2]]",
    ),
    content=(
      #|["[null,\"bc\",[],[2,3],[2]]"]
    ),
  )
}

///|
test "jq_compat_30: try [\"OK\", (.[] | error)] catch [\"KO\", .]" {
  inspect(
    run_jq(
      "try [\"OK\", (.[] | error)] catch [\"KO\", .]", "{\"a\":[\"b\"],\"c\":[\"d\"]}",
    ),
    content=(
      #|["[\"KO\",[\"b\"]]"]
    ),
  )
}

///|
test "jq_compat_31: .[-1] = 5" {
  inspect(
    run_jq(".[-1] = 5", "[0,1,2]"),
    content=(
      #|["[0,1,5]"]
    ),
  )
}

///|
test "jq_compat_32: .[-2] = 5" {
  inspect(
    run_jq(".[-2] = 5", "[0,1,2]"),
    content=(
      #|["[0,5,2]"]
    ),
  )
}

///|
test "jq_compat_33: .[]" {
  inspect(
    run_jq(".[]", "[1,2,3]"),
    content=(
      #|["1", "2", "3"]
    ),
  )
}

///|
test "jq_compat_34: 1,1" {
  inspect(
    run_jq("1,1", "[]"),
    content=(
      #|["1", "1"]
    ),
  )
}

///|
test "jq_compat_35: 1,." {
  inspect(
    run_jq("1,.", "[]"),
    content=(
      #|["1", "[]"]
    ),
  )
}

///|
test "jq_compat_36: [.]" {
  inspect(
    run_jq("[.]", "[2]"),
    content=(
      #|["[[2]]"]
    ),
  )
}

///|
test "jq_compat_37: [[2]]" {
  inspect(
    run_jq("[[2]]", "[3]"),
    content=(
      #|["[[2]]"]
    ),
  )
}

///|
test "jq_compat_38: [{}]" {
  inspect(
    run_jq("[{}]", "[2]"),
    content=(
      #|["[{}]"]
    ),
  )
}

///|
test "jq_compat_39: [.[]]" {
  inspect(
    run_jq("[.[]]", "[\"a\"]"),
    content=(
      #|["[\"a\"]"]
    ),
  )
}

///|
test "jq_compat_40: [(.,1),((.,.[]),(2,3))]" {
  inspect(
    run_jq("[(.,1),((.,.[]),(2,3))]", "[\"a\",\"b\"]"),
    content=(
      #|["[[\"a\",\"b\"],1,[\"a\",\"b\"],\"a\",\"b\",2,3]"]
    ),
  )
}

///|
test "jq_compat_41: [([5,5][]),.,.[]]" {
  inspect(
    run_jq("[([5,5][]),.,.[]]", "[1,2,3]"),
    content=(
      #|["[5,5,[1,2,3],1,2,3]"]
    ),
  )
}

///|
test "jq_compat_42: {x: (1,2)},{x:3} | .x" {
  inspect(
    run_jq("{x: (1,2)},{x:3} | .x", "null"),
    content=(
      #|["1", "2", "3"]
    ),
  )
}

///|
test "jq_compat_43: [.[-4,-3,-2,-1,0,1,2,3]]" {
  inspect(
    run_jq("[.[-4,-3,-2,-1,0,1,2,3]]", "[1,2,3]"),
    content=(
      #|["[null,1,2,3,1,2,3,null]"]
    ),
  )
}

///|
test "jq_compat_44: [range(0;10)]" {
  inspect(
    run_jq("[range(0;10)]", "null"),
    content=(
      #|["[0,1,2,3,4,5,6,7,8,9]"]
    ),
  )
}

///|
test "jq_compat_45: [range(0,1;3,4)]" {
  inspect(
    run_jq("[range(0,1;3,4)]", "null"),
    content=(
      #|["[0,1,2,0,1,2,3,1,2,1,2,3]"]
    ),
  )
}

///|
test "jq_compat_46: [range(0;10;3)]" {
  inspect(
    run_jq("[range(0;10;3)]", "null"),
    content=(
      #|["[0,3,6,9]"]
    ),
  )
}

///|
test "jq_compat_47: [range(0;10;-1)]" {
  inspect(
    run_jq("[range(0;10;-1)]", "null"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_48: [range(0;-5;-1)]" {
  inspect(
    run_jq("[range(0;-5;-1)]", "null"),
    content=(
      #|["[0,-1,-2,-3,-4]"]
    ),
  )
}

///|
test "jq_compat_49: [range(0,1;4,5;1,2)]" {
  inspect(
    run_jq("[range(0,1;4,5;1,2)]", "null"),
    content=(
      #|["[0,1,2,3,0,2,0,1,2,3,4,0,2,4,1,2,3,1,3,1,2,3,4,1,3]"]
    ),
  )
}

///|
test "jq_compat_50: [while(.<100; .*2)]" {
  inspect(
    run_jq("[while(.<100; .*2)]", "1"),
    content=(
      #|["[1,2,4,8,16,32,64]"]
    ),
  )
}

///|
test "jq_compat_51: [(label $here | .[] | if .>1 then break $here else . end), \"" {
  inspect(
    run_jq(
      "[(label $here | .[] | if .>1 then break $here else . end), \"hi!\"]", "[0,1,2]",
    ),
    content=(
      #|["[0,1,\"hi!\"]"]
    ),
  )
}

///|
test "jq_compat_52: [(label $here | .[] | if .>1 then break $here else . end), \"" {
  inspect(
    run_jq(
      "[(label $here | .[] | if .>1 then break $here else . end), \"hi!\"]", "[0,2,1]",
    ),
    content=(
      #|["[0,\"hi!\"]"]
    ),
  )
}

///|
test "jq_compat_53: [.[]|[.,1]|until(.[0] < 1; [.[0] - 1, .[1] * .[0]])|.[1]]" {
  inspect(
    run_jq(
      "[.[]|[.,1]|until(.[0] < 1; [.[0] - 1, .[1] * .[0]])|.[1]]", "[1,2,3,4,5]",
    ),
    content=(
      #|["[1,2,6,24,120]"]
    ),
  )
}

///|
test "jq_compat_54: [label $out | foreach .[] as $item ([3, null]; if .[0] < 1 t" {
  inspect(
    run_jq(
      "[label $out | foreach .[] as $item ([3, null]; if .[0] < 1 then break $out else [.[0] -1, $item] end; .[1])]",
      "[11,22,33,44,55,66,77,88,99]",
    ),
    content=(
      #|["[11,22,33]"]
    ),
  )
}

///|
test "jq_compat_55: [foreach range(5) as $item (0; $item)]" {
  inspect(
    run_jq("[foreach range(5) as $item (0; $item)]", "null"),
    content=(
      #|["[0,1,2,3,4]"]
    ),
  )
}

///|
test "jq_compat_56: [foreach .[] as [$i, $j] (0; . + $i - $j)]" {
  inspect(
    run_jq(
      "[foreach .[] as [$i, $j] (0; . + $i - $j)]", "[[2,1], [5,3], [6,4]]",
    ),
    content=(
      #|["[1,3,5]"]
    ),
  )
}

///|
test "jq_compat_57: [foreach .[] as {a:$a} (0; . + $a; -.)]" {
  inspect(
    run_jq(
      "[foreach .[] as {a:$a} (0; . + $a; -.)]", "[{\"a\":1}, {\"b\":2}, {\"a\":3, \"b\":4}]",
    ),
    content=(
      #|["[-1,-1,-4]"]
    ),
  )
}

///|
test "jq_compat_58: [-foreach -.[] as $x (0; . + $x)]" {
  inspect(
    run_jq("[-foreach -.[] as $x (0; . + $x)]", "[1,2,3]"),
    content=(
      #|["[1,3,6]"]
    ),
  )
}

///|
test "jq_compat_59: [foreach .[] / .[] as $i (0; . + $i)]" {
  inspect(
    run_jq("[foreach .[] / .[] as $i (0; . + $i)]", "[1,2]"),
    content=(
      #|["[1,3,3.5,4.5]"]
    ),
  )
}

///|
test "jq_compat_60: [foreach .[] as $x (0; . + $x) as $x | $x]" {
  inspect(
    run_jq("[foreach .[] as $x (0; . + $x) as $x | $x]", "[1,2,3]"),
    content=(
      #|["[1,3,6]"]
    ),
  )
}

///|
test "jq_compat_61: [limit(3; .[])]" {
  inspect(
    run_jq("[limit(3; .[])]", "[11,22,33,44,55,66,77,88,99]"),
    content=(
      #|["[11,22,33]"]
    ),
  )
}

///|
test "jq_compat_62: [limit(0; error)]" {
  inspect(
    run_jq("[limit(0; error)]", "\"badness\""),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_63: [limit(1; 1, error)]" {
  inspect(
    run_jq("[limit(1; 1, error)]", "\"badness\""),
    content=(
      #|["[1]"]
    ),
  )
}

///|
test "jq_compat_64: try limit(-1; error) catch ." {
  inspect(
    run_jq("try limit(-1; error) catch .", "null"),
    content=(
      #|["\"limit doesn't support negative count\""]
    ),
  )
}

///|
test "jq_compat_65: [skip(3; .[])]" {
  inspect(
    run_jq("[skip(3; .[])]", "[1,2,3,4,5,6,7,8,9]"),
    content=(
      #|["[4,5,6,7,8,9]"]
    ),
  )
}

///|
test "jq_compat_66: [skip(0,2,3,4; .[])]" {
  inspect(
    run_jq("[skip(0,2,3,4; .[])]", "[1,2,3]"),
    content=(
      #|["[1,2,3,3]"]
    ),
  )
}

///|
test "jq_compat_67: [skip(3; .[])]" {
  inspect(
    run_jq("[skip(3; .[])]", "[]"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_68: try skip(-1; error) catch ." {
  inspect(
    run_jq("try skip(-1; error) catch .", "null"),
    content=(
      #|["\"skip doesn't support negative count\""]
    ),
  )
}

///|
test "jq_compat_69: nth(1; 0,1,error(\"foo\"))" {
  inspect(
    run_jq("nth(1; 0,1,error(\"foo\"))", "null"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_70: [first(range(.)), last(range(.))]" {
  inspect(
    run_jq("[first(range(.)), last(range(.))]", "10"),
    content=(
      #|["[0,9]"]
    ),
  )
}

///|
test "jq_compat_71: [first(range(.)), last(range(.))]" {
  inspect(
    run_jq("[first(range(.)), last(range(.))]", "0"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_72: [nth(0,5,9,10,15; range(.)), try nth(-1; range(.)) catch .]" {
  inspect(
    run_jq("[nth(0,5,9,10,15; range(.)), try nth(-1; range(.)) catch .]", "10"),
    content=(
      #|["[0,5,9,\"nth doesn't support negative indices\"]"]
    ),
  )
}

///|
test "jq_compat_73: first(1,error(\"foo\"))" {
  inspect(
    run_jq("first(1,error(\"foo\"))", "null"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_74: [limit(5,7; range(9))]" {
  inspect(
    run_jq("[limit(5,7; range(9))]", "null"),
    content=(
      #|["[0,1,2,3,4,0,1,2,3,4,5,6]"]
    ),
  )
}

///|
test "jq_compat_75: [nth(5,7; range(9;0;-1))]" {
  inspect(
    run_jq("[nth(5,7; range(9;0;-1))]", "null"),
    content=(
      #|["[4,2]"]
    ),
  )
}

///|
test "jq_compat_76: [range(0,1,2;4,3,2;2,3)]" {
  inspect(
    run_jq("[range(0,1,2;4,3,2;2,3)]", "null"),
    content=(
      #|["[0,2,0,3,0,2,0,0,0,1,3,1,1,1,1,1,2,2,2,2]"]
    ),
  )
}

///|
test "jq_compat_77: [range(3,5)]" {
  inspect(
    run_jq("[range(3,5)]", "null"),
    content=(
      #|["[0,1,2,0,1,2,3,4]"]
    ),
  )
}

///|
test "jq_compat_78: [(index(\",\",\"|\"), rindex(\",\",\"|\")), indices(\",\",\"|\")]" {
  inspect(
    run_jq(
      "[(index(\",\",\"|\"), rindex(\",\",\"|\")), indices(\",\",\"|\")]", "\"a,b|c,d,e||f,g,h,|,|,i,j\"",
    ),
    content=(
      #|["[1,3,22,19,[1,5,7,12,14,16,18,20,22],[3,9,10,17,19]]"]
    ),
  )
}

///|
test "jq_compat_79: join(\",\",\"/\")" {
  inspect(
    run_jq("join(\",\",\"/\")", "[\"a\",\"b\",\"c\",\"d\"]"),
    content=(
      #|["\"a,b,c,d\"", "\"a/b/c/d\""]
    ),
  )
}

///|
test "jq_compat_80: [.[]|join(\"a\")]" {
  inspect(
    run_jq("[.[]|join(\"a\")]", "[[],[\"\"],[\"\",\"\"],[\"\",\"\",\"\"]]"),
    content=(
      #|["[\"\",\"\",\"a\",\"aa\"]"]
    ),
  )
}

///|
test "jq_compat_81: [.[3:2], .[-5:4], .[:-2], .[-2:], .[3:3][1:], .[10:]]" {
  inspect(
    run_jq(
      "[.[3:2], .[-5:4], .[:-2], .[-2:], .[3:3][1:], .[10:]]", "[0,1,2,3,4,5,6]",
    ),
    content=(
      #|["[[],[2,3],[0,1,2,3,4],[5,6],[],[]]"]
    ),
  )
}

///|
test "jq_compat_82: [.[3:2], .[-5:4], .[:-2], .[-2:], .[3:3][1:], .[10:]]" {
  inspect(
    run_jq(
      "[.[3:2], .[-5:4], .[:-2], .[-2:], .[3:3][1:], .[10:]]", "\"abcdefghi\"",
    ),
    content=(
      #|["[\"\",\"\",\"abcdefg\",\"hi\",\"\",\"\"]"]
    ),
  )
}

///|
test "jq_compat_83: del(.[2:4],.[0],.[-2:])" {
  inspect(
    run_jq("del(.[2:4],.[0],.[-2:])", "[0,1,2,3,4,5,6,7]"),
    content=(
      #|["[1,4,5]"]
    ),
  )
}

///|
test "jq_compat_84: .[2:4] = ([], [\"a\",\"b\"], [\"a\",\"b\",\"c\"])" {
  inspect(
    run_jq(
      ".[2:4] = ([], [\"a\",\"b\"], [\"a\",\"b\",\"c\"])", "[0,1,2,3,4,5,6,7]",
    ),
    content=(
      #|["[0,1,[],[],4,5,6,7]", "[0,1,[\"a\",\"b\"],[\"a\",\"b\"],4,5,6,7]", "[0,1,[\"a\",\"b\",\"c\"],[\"a\",\"b\",\"c\"],4,5,6,7]"]
    ),
  )
}

///|
test "jq_compat_85: reduce range(65540;65536;-1) as $i ([]; .[$i] = $i)|.[65536:" {
  inspect(
    run_jq(
      "reduce range(65540;65536;-1) as $i ([]; .[$i] = $i)|.[65536:]", "null",
    ),
    content=(
      #|["[null,65537,65538,65539,65540]"]
    ),
  )
}

///|
test "jq_compat_86: 1 as $x | 2 as $y | [$x,$y,$x]" {
  inspect(
    run_jq("1 as $x | 2 as $y | [$x,$y,$x]", "null"),
    content=(
      #|["[1,2,1]"]
    ),
  )
}

///|
test "jq_compat_87: [1,2,3][] as $x | [[4,5,6,7][$x]]" {
  inspect(
    run_jq("[1,2,3][] as $x | [[4,5,6,7][$x]]", "null"),
    content=(
      #|["[5]", "[6]", "[7]"]
    ),
  )
}

///|
test "jq_compat_88: 42 as $x | . | . | . + 432 | $x + 1" {
  inspect(
    run_jq("42 as $x | . | . | . + 432 | $x + 1", "34324"),
    content=(
      #|["43"]
    ),
  )
}

///|
test "jq_compat_89: \"x\" as $x | \"a\"+\"y\" as $y | $x+\",\"+$y" {
  inspect(
    run_jq("\"x\" as $x | \"a\"+\"y\" as $y | $x+\",\"+$y", "null"),
    content=(
      #|["\"x,ay\""]
    ),
  )
}

///|
test "jq_compat_90: 1 as $x | [$x,$x,$x as $x | $x]" {
  inspect(
    run_jq("1 as $x | [$x,$x,$x as $x | $x]", "null"),
    content=(
      #|["[1,1,1]"]
    ),
  )
}

///|
test "jq_compat_91: [1, {c:3, d:4}] as [$a, {c:$b, b:$c}] | $a, $b, $c" {
  inspect(
    run_jq("[1, {c:3, d:4}] as [$a, {c:$b, b:$c}] | $a, $b, $c", "null"),
    content=(
      #|["1", "3", "null"]
    ),
  )
}

///|
test "jq_compat_92: . as {as: $kw, \"str\": $str, (\"e\"+\"x\"+\"p\"): $exp} | [$kw, $st" {
  inspect(
    run_jq(
      ". as {as: $kw, \"str\": $str, (\"e\"+\"x\"+\"p\"): $exp} | [$kw, $str, $exp]",
      "{\"as\": 1, \"str\": 2, \"exp\": 3}",
    ),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "jq_compat_93: .[] as [$a, $b] | [$b, $a]" {
  inspect(
    run_jq(".[] as [$a, $b] | [$b, $a]", "[[1], [1, 2, 3]]"),
    content=(
      #|["[null,1]", "[2,1]"]
    ),
  )
}

///|
test "jq_compat_94: . as $i | . as [$i] | $i" {
  inspect(
    run_jq(". as $i | . as [$i] | $i", "[0]"),
    content=(
      #|["0"]
    ),
  )
}

///|
test "jq_compat_95: . as [$i] | . as $i | $i" {
  inspect(
    run_jq(". as [$i] | . as $i | $i", "[0]"),
    content=(
      #|["[0]"]
    ),
  )
}

///|
test "jq_compat_96: 1+1" {
  inspect(
    run_jq("1+1", "null"),
    content=(
      #|["2"]
    ),
  )
}

///|
test "jq_compat_97: 1+1" {
  inspect(
    run_jq("1+1", "\"wtasdf\""),
    content=(
      #|["2"]
    ),
  )
}

///|
test "jq_compat_98: 2-1" {
  inspect(
    run_jq("2-1", "null"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_99: 2-(-1)" {
  inspect(
    run_jq("2-(-1)", "null"),
    content=(
      #|["3"]
    ),
  )
}

///|
test "jq_compat_100: .+4" {
  inspect(
    run_jq(".+4", "15"),
    content=(
      #|["19"]
    ),
  )
}

///|
test "jq_compat_101: .+null" {
  inspect(
    run_jq(".+null", "{\"a\":42}"),
    content=(
      #|["{\"a\":42}"]
    ),
  )
}

///|
test "jq_compat_102: null+." {
  inspect(
    run_jq("null+.", "null"),
    content=(
      #|["null"]
    ),
  )
}

///|
test "jq_compat_103: .a+.b" {
  inspect(
    run_jq(".a+.b", "{\"a\":42}"),
    content=(
      #|["42"]
    ),
  )
}

///|
test "jq_compat_104: [1,2,3] + [.]" {
  inspect(
    run_jq("[1,2,3] + [.]", "null"),
    content=(
      #|["[1,2,3,null]"]
    ),
  )
}

///|
test "jq_compat_105: {\"a\":1} + {\"b\":2} + {\"c\":3}" {
  inspect(
    run_jq("{\"a\":1} + {\"b\":2} + {\"c\":3}", "\"asdfasdf\""),
    content=(
      #|["{\"a\":1,\"b\":2,\"c\":3}"]
    ),
  )
}

///|
test "jq_compat_106: \"asdf\" + \"jkl;\" + . + . + ." {
  inspect(
    run_jq("\"asdf\" + \"jkl;\" + . + . + .", "\"some string\""),
    content=(
      #|["\"asdfjkl;some stringsome stringsome string\""]
    ),
  )
}

///|
test "jq_compat_107: \"\\u0000\\u0020\\u0000\" + ." {
  inspect(
    run_jq("\"\\u0000\\u0020\\u0000\" + .", "\"\\u0000\\u0020\\u0000\""),
    content=(
      #|["\"\\\\u0000\\\\u0020\\\\u0000\\u0000 \\u0000\""]
    ),
  )
}

///|
test "jq_compat_108: 42 - ." {
  inspect(
    run_jq("42 - .", "11"),
    content=(
      #|["31"]
    ),
  )
}

///|
test "jq_compat_109: [1,2,3,4,1] - [.,3]" {
  inspect(
    run_jq("[1,2,3,4,1] - [.,3]", "1"),
    content=(
      #|["[2,4]"]
    ),
  )
}

///|
test "jq_compat_110: [-1 as $x | 1,$x]" {
  inspect(
    run_jq("[-1 as $x | 1,$x]", "null"),
    content=(
      #|["[1,-1]"]
    ),
  )
}

///|
test "jq_compat_111: [10 * 20, 20 / .]" {
  inspect(
    run_jq("[10 * 20, 20 / .]", "4"),
    content=(
      #|["[200,5]"]
    ),
  )
}

///|
test "jq_compat_112: 1 + 2 * 2 + 10 / 2" {
  inspect(
    run_jq("1 + 2 * 2 + 10 / 2", "null"),
    content=(
      #|["10"]
    ),
  )
}

///|
test "jq_compat_113: [16 / 4 / 2, 16 / 4 * 2, 16 - 4 - 2, 16 - 4 + 2]" {
  inspect(
    run_jq("[16 / 4 / 2, 16 / 4 * 2, 16 - 4 - 2, 16 - 4 + 2]", "null"),
    content=(
      #|["[2,8,10,14]"]
    ),
  )
}

///|
test "jq_compat_114: 25 % 7" {
  inspect(
    run_jq("25 % 7", "null"),
    content=(
      #|["4"]
    ),
  )
}

///|
test "jq_compat_115: 49732 % 472" {
  inspect(
    run_jq("49732 % 472", "null"),
    content=(
      #|["172"]
    ),
  )
}

///|
test "jq_compat_116: [(infinite, -infinite) % (1, -1, infinite)]" {
  inspect(
    run_jq("[(infinite, -infinite) % (1, -1, infinite)]", "null"),
    content=(
      #|["[0,0,0,0,0,-1]"]
    ),
  )
}

///|
test "jq_compat_117: [nan % 1, 1 % nan | isnan]" {
  inspect(
    run_jq("[nan % 1, 1 % nan | isnan]", "null"),
    content=(
      #|["[true,true]"]
    ),
  )
}

///|
test "jq_compat_118: 1 + tonumber + (\"10\" | tonumber)" {
  inspect(
    run_jq("1 + tonumber + (\"10\" | tonumber)", "4"),
    content=(
      #|["15"]
    ),
  )
}

///|
test "jq_compat_119: \"123\\u0000456\" | try tonumber catch ." {
  inspect(
    run_jq("\"123\\u0000456\" | try tonumber catch .", "null"),
    content=(
      #|["128090000456"]
    ),
  )
}

///|
test "jq_compat_120: map(toboolean)" {
  inspect(
    run_jq("map(toboolean)", "[\"false\",\"true\",false,true]"),
    content=(
      #|["[false,true,false,true]"]
    ),
  )
}

///|
test "jq_compat_121: .[] | try toboolean catch ." {
  inspect(
    run_jq(
      ".[] | try toboolean catch .", "[null,0,\"tru\",\"truee\",\"fals\",\"falsee\",[],{}]",
    ),
    content=(
      #|["\"null (null) cannot be parsed as a boolean\"", "\"number (0) cannot be parsed as a boolean\"", "\"string (\\\"tru\\\") cannot be parsed as a boolean\"", "\"string (\\\"truee\\\") cannot be parsed as a boolean\"", "\"string (\\\"fals\\\") cannot be parsed as a boolean\"", "\"string (\\\"falsee\\\") cannot be parsed as a boolean\"", "\"array ([]) cannot be parsed as a boolean\"", "\"object ({}) cannot be parsed as a boolean\""]
    ),
  )
}

///|
test "jq_compat_122: \"true\\u0000x\", \"false\\u0000\" | try toboolean catch ." {
  inspect(
    run_jq("\"true\\u0000x\", \"false\\u0000\" | try toboolean catch .", "null"),
    content=(
      #|["\"string (\\\"true\\\\\\\\u0000x\\\") cannot be parsed as a boolean\"", "\"string (\\\"false\\\\\\\\u0000\\\") cannot be parsed as a boolean\""]
    ),
  )
}

///|
test "jq_compat_123: [{\"a\":42},.object,10,.num,false,true,null,\"b\",[1,4]] | .[] a" {
  inspect(
    run_jq(
      "[{\"a\":42},.object,10,.num,false,true,null,\"b\",[1,4]] | .[] as $x | [$x == .[]]",
      "{\"object\": {\"a\":42}, \"num\":10.0}",
    ),
    content=(
      #|["[true,true,false,false,false,false,false,false,false]", "[true,true,false,false,false,false,false,false,false]", "[false,false,true,true,false,false,false,false,false]", "[false,false,true,true,false,false,false,false,false]", "[false,false,false,false,true,false,false,false,false]", "[false,false,false,false,false,true,false,false,false]", "[false,false,false,false,false,false,true,false,false]", "[false,false,false,false,false,false,false,true,false]", "[false,false,false,false,false,false,false,false,true]"]
    ),
  )
}

///|
test "jq_compat_124: [.[] | length]" {
  inspect(
    run_jq(
      "[.[] | length]", "[[], {}, [1,2], {\"a\":42}, \"asdf\", \"\\u03bc\"]",
    ),
    content=(
      #|["[0,0,2,1,4,1]"]
    ),
  )
}

///|
test "jq_compat_125: utf8bytelength" {
  inspect(
    run_jq("utf8bytelength", "\"asdf\\u03bc\""),
    content=(
      #|["6"]
    ),
  )
}

///|
test "jq_compat_126: map(keys)" {
  inspect(
    run_jq(
      "map(keys)", "[{}, {\"abcd\":1,\"abc\":2,\"abcde\":3}, {\"x\":1, \"z\": 3, \"y\":2}]",
    ),
    content=(
      #|["[[],[\"abc\",\"abcd\",\"abcde\"],[\"x\",\"y\",\"z\"]]"]
    ),
  )
}

///|
test "jq_compat_127: [1,2,empty,3,empty,4]" {
  inspect(
    run_jq("[1,2,empty,3,empty,4]", "null"),
    content=(
      #|["[1,2,3,4]"]
    ),
  )
}

///|
test "jq_compat_128: map(add)" {
  inspect(
    run_jq(
      "map(add)", "[[], [1,2,3], [\"a\",\"b\",\"c\"], [[3],[4,5],[6]], [{\"a\":1}, {\"b\":2}, {\"a\":3}]]",
    ),
    content=(
      #|["[null,6,\"abc\",[3,4,5,6],{\"a\":3,\"b\":2}]"]
    ),
  )
}

///|
test "jq_compat_129: map_values(.+1)" {
  inspect(
    run_jq("map_values(.+1)", "[0,1,2]"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "jq_compat_130: def f: (1000,2000); f" {
  inspect(
    run_jq("def f: (1000,2000); f", "123412345"),
    content=(
      #|["1000", "2000"]
    ),
  )
}

///|
test "jq_compat_131: def f(a;b;c;d;e;f): [a+1,b,c,d,e,f]; f(.[0];.[1];.[0];.[0];." {
  inspect(
    run_jq(
      "def f(a;b;c;d;e;f): [a+1,b,c,d,e,f]; f(.[0];.[1];.[0];.[0];.[0];.[0])", "[1,2]",
    ),
    content=(
      #|["[2,2,1,1,1,1]"]
    ),
  )
}

///|
test "jq_compat_132: def a: 0; . | a" {
  inspect(
    run_jq("def a: 0; . | a", "null"),
    content=(
      #|["0"]
    ),
  )
}

///|
test "jq_compat_133: def f(a;b;c;d;e;f;g;h;i;j): [j,i,h,g,f,e,d,c,b,a]; f(.[0];.[" {
  inspect(
    run_jq(
      "def f(a;b;c;d;e;f;g;h;i;j): [j,i,h,g,f,e,d,c,b,a]; f(.[0];.[1];.[2];.[3];.[4];.[5];.[6];.[7];.[8];.[9])",
      "[0,1,2,3,4,5,6,7,8,9]",
    ),
    content=(
      #|["[9,8,7,6,5,4,3,2,1,0]"]
    ),
  )
}

///|
test "jq_compat_134: ([1,2] + [4,5])" {
  inspect(
    run_jq("([1,2] + [4,5])", "[1,2,3]"),
    content=(
      #|["[1,2,4,5]"]
    ),
  )
}

///|
test "jq_compat_135: true" {
  inspect(
    run_jq("true", "[1]"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_136: null,1,null" {
  inspect(
    run_jq("null,1,null", "\"hello\""),
    content=(
      #|["null", "1", "null"]
    ),
  )
}

///|
test "jq_compat_137: [1,2,3]" {
  inspect(
    run_jq("[1,2,3]", "[5,6]"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "jq_compat_138: [.[]|floor]" {
  inspect(
    run_jq("[.[]|floor]", "[-1.1,1.1,1.9]"),
    content=(
      #|["[-2,1,1]"]
    ),
  )
}

///|
test "jq_compat_139: [.[]|sqrt]" {
  inspect(
    run_jq("[.[]|sqrt]", "[4,9]"),
    content=(
      #|["[2,3]"]
    ),
  )
}

///|
test "jq_compat_140: (add / length) as $m | map((. - $m) as $d | $d * $d) | add /" {
  inspect(
    run_jq(
      "(add / length) as $m | map((. - $m) as $d | $d * $d) | add / length | sqrt",
      "[2,4,4,4,5,5,7,9]",
    ),
    content=(
      #|["2"]
    ),
  )
}

///|
test "jq_compat_141: atan * 4 * 1000000|floor / 1000000" {
  inspect(
    run_jq("atan * 4 * 1000000|floor / 1000000", "1"),
    content=(
      #|["3.141592"]
    ),
  )
}

///|
test "jq_compat_142: [(3.141592 / 2) * (range(0;20) / 20)|cos * 1000000|floor / 1" {
  inspect(
    run_jq(
      "[(3.141592 / 2) * (range(0;20) / 20)|cos * 1000000|floor / 1000000]", "null",
    ),
    content=(
      #|["[1,0.996917,0.987688,0.972369,0.951056,0.923879,0.891006,0.85264,0.809017,0.760406,0.707106,0.649448,0.587785,0.522498,0.45399,0.382683,0.309017,0.233445,0.156434,0.078459]"]
    ),
  )
}

///|
test "jq_compat_143: [(3.141592 / 2) * (range(0;20) / 20)|sin * 1000000|floor / 1" {
  inspect(
    run_jq(
      "[(3.141592 / 2) * (range(0;20) / 20)|sin * 1000000|floor / 1000000]", "null",
    ),
    content=(
      #|["[0,0.078459,0.156434,0.233445,0.309016,0.382683,0.45399,0.522498,0.587785,0.649447,0.707106,0.760405,0.809016,0.85264,0.891006,0.923879,0.951056,0.972369,0.987688,0.996917]"]
    ),
  )
}

///|
test "jq_compat_144: def f(x): x | x; f([.], . + [42])" {
  inspect(
    run_jq("def f(x): x | x; f([.], . + [42])", "[1,2,3]"),
    content=(
      #|["[[[1,2,3]]]", "[[1,2,3],42]", "[[1,2,3,42]]", "[1,2,3,42,42]"]
    ),
  )
}

///|
test "jq_compat_145: [[20,10][1,0] as $x | def f: (100,200) as $y | def g: [$x + " {
  inspect(
    run_jq(
      "[[20,10][1,0] as $x | def f: (100,200) as $y | def g: [$x + $y, .]; . + $x | g; f[0] | [f][0][1] | f]",
      "999999999",
    ),
    content=(
      #|["[[110,130],[210,130],[110,230],[210,230],[120,160],[220,160],[120,260],[220,260]]"]
    ),
  )
}

///|
test "jq_compat_146: def fac: if . == 1 then 1 else . * (. - 1 | fac) end; [.[] |" {
  inspect(
    run_jq(
      "def fac: if . == 1 then 1 else . * (. - 1 | fac) end; [.[] | fac]", "[1,2,3,4]",
    ),
    content=(
      #|["[1,2,6,24]"]
    ),
  )
}

///|
test "jq_compat_147: reduce .[] as $x (0; . + $x)" {
  inspect(
    run_jq("reduce .[] as $x (0; . + $x)", "[1,2,4]"),
    content=(
      #|["7"]
    ),
  )
}

///|
test "jq_compat_148: reduce .[] as [$i, {j:$j}] (0; . + $i - $j)" {
  inspect(
    run_jq(
      "reduce .[] as [$i, {j:$j}] (0; . + $i - $j)", "[[2,{\"j\":1}], [5,{\"j\":3}], [6,{\"j\":4}]]",
    ),
    content=(
      #|["5"]
    ),
  )
}

///|
test "jq_compat_149: reduce [[1,2,10], [3,4,10]][] as [$i,$j] (0; . + $i * $j)" {
  inspect(
    run_jq("reduce [[1,2,10], [3,4,10]][] as [$i,$j] (0; . + $i * $j)", "null"),
    content=(
      #|["14"]
    ),
  )
}

///|
test "jq_compat_150: [-reduce -.[] as $x (0; . + $x)]" {
  inspect(
    run_jq("[-reduce -.[] as $x (0; . + $x)]", "[1,2,3]"),
    content=(
      #|["[6]"]
    ),
  )
}

///|
test "jq_compat_151: [reduce .[] / .[] as $i (0; . + $i)]" {
  inspect(
    run_jq("[reduce .[] / .[] as $i (0; . + $i)]", "[1,2]"),
    content=(
      #|["[4.5]"]
    ),
  )
}

///|
test "jq_compat_152: reduce .[] as $x (0; . + $x) as $x | $x" {
  inspect(
    run_jq("reduce .[] as $x (0; . + $x) as $x | $x", "[1,2,3]"),
    content=(
      #|["6"]
    ),
  )
}

///|
test "jq_compat_153: reduce . as $n (.; .)" {
  inspect(
    run_jq("reduce . as $n (.; .)", "null"),
    content=(
      #|["null"]
    ),
  )
}

///|
test "jq_compat_154: . as {$a, b: [$c, {$d}]} | [$a, $c, $d]" {
  inspect(
    run_jq(
      ". as {$a, b: [$c, {$d}]} | [$a, $c, $d]", "{\"a\":1, \"b\":[2,{\"d\":3}]}",
    ),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "jq_compat_155: . as {$a, $b:[$c, $d]}| [$a, $b, $c, $d]" {
  inspect(
    run_jq(
      ". as {$a, $b:[$c, $d]}| [$a, $b, $c, $d]", "{\"a\":1, \"b\":[2,{\"d\":3}]}",
    ),
    content=(
      #|["ERROR: expected RBrace but got Colon"]
    ),
  )
}

///|
test "jq_compat_156: .[] | . as {$a, b: [$c, {$d}]} ?// [$a, {$b}, $e] ?// $f | [" {
  inspect(
    run_jq(
      ".[] | . as {$a, b: [$c, {$d}]} ?// [$a, {$b}, $e] ?// $f | [$a, $b, $c, $d, $e, $f]",
      "[{\"a\":1, \"b\":[2,{\"d\":3}]}, [4, {\"b\":5, \"c\":6}, 7, 8, 9], \"foo\"]",
    ),
    content=(
      #|["[1,null,2,3,null,null]", "[4,5,null,null,7,null]", "[null,null,null,null,null,\"foo\"]"]
    ),
  )
}

///|
test "jq_compat_157: .[] | . as {a:$a} ?// {a:$a} ?// $a | $a" {
  inspect(
    run_jq(".[] | . as {a:$a} ?// {a:$a} ?// $a | $a", "[[3],[4],[5],6]"),
    content=(
      #|["[3]", "[4]", "[5]", "6"]
    ),
  )
}

///|
test "jq_compat_158: .[] as {a:$a} ?// {a:$a} ?// $a | $a" {
  inspect(
    run_jq(".[] as {a:$a} ?// {a:$a} ?// $a | $a", "[[3],[4],[5],6]"),
    content=(
      #|["[3]", "[4]", "[5]", "6"]
    ),
  )
}

///|
test "jq_compat_159: [[3],[4],[5],6][] | . as {a:$a} ?// {a:$a} ?// $a | $a" {
  inspect(
    run_jq("[[3],[4],[5],6][] | . as {a:$a} ?// {a:$a} ?// $a | $a", "null"),
    content=(
      #|["[3]", "[4]", "[5]", "6"]
    ),
  )
}

///|
test "jq_compat_160: [[3],[4],[5],6] | .[] as {a:$a} ?// {a:$a} ?// $a | $a" {
  inspect(
    run_jq("[[3],[4],[5],6] | .[] as {a:$a} ?// {a:$a} ?// $a | $a", "null"),
    content=(
      #|["[3]", "[4]", "[5]", "6"]
    ),
  )
}

///|
test "jq_compat_161: .[] | . as {a:$a} ?// $a ?// {a:$a} | $a" {
  inspect(
    run_jq(".[] | . as {a:$a} ?// $a ?// {a:$a} | $a", "[[3],[4],[5],6]"),
    content=(
      #|["[3]", "[4]", "[5]", "6"]
    ),
  )
}

///|
test "jq_compat_162: .[] as {a:$a} ?// $a ?// {a:$a} | $a" {
  inspect(
    run_jq(".[] as {a:$a} ?// $a ?// {a:$a} | $a", "[[3],[4],[5],6]"),
    content=(
      #|["[3]", "[4]", "[5]", "6"]
    ),
  )
}

///|
test "jq_compat_163: [[3],[4],[5],6][] | . as {a:$a} ?// $a ?// {a:$a} | $a" {
  inspect(
    run_jq("[[3],[4],[5],6][] | . as {a:$a} ?// $a ?// {a:$a} | $a", "null"),
    content=(
      #|["[3]", "[4]", "[5]", "6"]
    ),
  )
}

///|
test "jq_compat_164: [[3],[4],[5],6] | .[] as {a:$a} ?// $a ?// {a:$a} | $a" {
  inspect(
    run_jq("[[3],[4],[5],6] | .[] as {a:$a} ?// $a ?// {a:$a} | $a", "null"),
    content=(
      #|["[3]", "[4]", "[5]", "6"]
    ),
  )
}

///|
test "jq_compat_165: .[] | . as $a ?// {a:$a} ?// {a:$a} | $a" {
  inspect(
    run_jq(".[] | . as $a ?// {a:$a} ?// {a:$a} | $a", "[[3],[4],[5],6]"),
    content=(
      #|["[3]", "[4]", "[5]", "6"]
    ),
  )
}

///|
test "jq_compat_166: .[] as $a ?// {a:$a} ?// {a:$a} | $a" {
  inspect(
    run_jq(".[] as $a ?// {a:$a} ?// {a:$a} | $a", "[[3],[4],[5],6]"),
    content=(
      #|["[3]", "[4]", "[5]", "6"]
    ),
  )
}

///|
test "jq_compat_167: [[3],[4],[5],6][] | . as $a ?// {a:$a} ?// {a:$a} | $a" {
  inspect(
    run_jq("[[3],[4],[5],6][] | . as $a ?// {a:$a} ?// {a:$a} | $a", "null"),
    content=(
      #|["[3]", "[4]", "[5]", "6"]
    ),
  )
}

///|
test "jq_compat_168: [[3],[4],[5],6] | .[] as $a ?// {a:$a} ?// {a:$a} | $a" {
  inspect(
    run_jq("[[3],[4],[5],6] | .[] as $a ?// {a:$a} ?// {a:$a} | $a", "null"),
    content=(
      #|["[3]", "[4]", "[5]", "6"]
    ),
  )
}

///|
test "jq_compat_169: . as $dot|any($dot[];not)" {
  inspect(
    run_jq(". as $dot|any($dot[];not)", "[1,2,3,4,true,false,1,2,3,4,5]"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_170: . as $dot|any($dot[];not)" {
  inspect(
    run_jq(". as $dot|any($dot[];not)", "[1,2,3,4,true]"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_171: . as $dot|all($dot[];.)" {
  inspect(
    run_jq(". as $dot|all($dot[];.)", "[1,2,3,4,true,false,1,2,3,4,5]"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_172: . as $dot|all($dot[];.)" {
  inspect(
    run_jq(". as $dot|all($dot[];.)", "[1,2,3,4,true]"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_173: any(true, error; .)" {
  inspect(
    run_jq("any(true, error; .)", "\"badness\""),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_174: all(false, error; .)" {
  inspect(
    run_jq("all(false, error; .)", "\"badness\""),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_175: any(not)" {
  inspect(
    run_jq("any(not)", "[]"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_176: all(not)" {
  inspect(
    run_jq("all(not)", "[]"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_177: any(not)" {
  inspect(
    run_jq("any(not)", "[false]"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_178: all(not)" {
  inspect(
    run_jq("all(not)", "[false]"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_179: [any,all]" {
  inspect(
    run_jq("[any,all]", "[]"),
    content=(
      #|["[false,true]"]
    ),
  )
}

///|
test "jq_compat_180: [any,all]" {
  inspect(
    run_jq("[any,all]", "[true]"),
    content=(
      #|["[true,true]"]
    ),
  )
}

///|
test "jq_compat_181: [any,all]" {
  inspect(
    run_jq("[any,all]", "[false]"),
    content=(
      #|["[false,false]"]
    ),
  )
}

///|
test "jq_compat_182: [any,all]" {
  inspect(
    run_jq("[any,all]", "[true,false]"),
    content=(
      #|["[true,false]"]
    ),
  )
}

///|
test "jq_compat_183: [any,all]" {
  inspect(
    run_jq("[any,all]", "[null,null,true]"),
    content=(
      #|["[true,false]"]
    ),
  )
}

///|
test "jq_compat_184: path(.foo[0,1])" {
  inspect(
    run_jq("path(.foo[0,1])", "null"),
    content=(
      #|["[\"foo\",0]", "[\"foo\",1]"]
    ),
  )
}

///|
test "jq_compat_185: path(.[] | select(.>3))" {
  inspect(
    run_jq("path(.[] | select(.>3))", "[1,5,3]"),
    content=(
      #|["[1]"]
    ),
  )
}

///|
test "jq_compat_186: path(.)" {
  inspect(
    run_jq("path(.)", "42"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_187: try path(.a | map(select(.b == 0))) catch ." {
  inspect(
    run_jq("try path(.a | map(select(.b == 0))) catch .", "{\"a\":[{\"b\":0}]}"),
    content=(
      #|["\"Invalid path expression\""]
    ),
  )
}

///|
test "jq_compat_188: try path(.a | map(select(.b == 0)) | .[0]) catch ." {
  inspect(
    run_jq(
      "try path(.a | map(select(.b == 0)) | .[0]) catch .", "{\"a\":[{\"b\":0}]}",
    ),
    content=(
      #|["\"Invalid path expression\""]
    ),
  )
}

///|
test "jq_compat_189: try path(.a | map(select(.b == 0)) | .c) catch ." {
  inspect(
    run_jq(
      "try path(.a | map(select(.b == 0)) | .c) catch .", "{\"a\":[{\"b\":0}]}",
    ),
    content=(
      #|["\"Invalid path expression\""]
    ),
  )
}

///|
test "jq_compat_190: try path(.a | map(select(.b == 0)) | .[]) catch ." {
  inspect(
    run_jq(
      "try path(.a | map(select(.b == 0)) | .[]) catch .", "{\"a\":[{\"b\":0}]}",
    ),
    content=(
      #|["\"Invalid path expression\""]
    ),
  )
}

///|
test "jq_compat_191: path(.a[path(.b)[0]])" {
  inspect(
    run_jq("path(.a[path(.b)[0]])", "{\"a\":{\"b\":0}}"),
    content=(
      #|["[\"a\",\"b\"]"]
    ),
  )
}

///|
test "jq_compat_192: [paths]" {
  inspect(
    run_jq("[paths]", "[1,[[],{\"a\":2}]]"),
    content=(
      #|["[[0],[1],[1,0],[1,1],[1,1,\"a\"]]"]
    ),
  )
}

///|
test "jq_compat_193: [\"foo\",1] as $p | getpath($p), setpath($p; 20), delpaths([$p" {
  inspect(
    run_jq(
      "[\"foo\",1] as $p | getpath($p), setpath($p; 20), delpaths([$p])", "{\"bar\": 42, \"foo\": [\"a\", \"b\", \"c\", \"d\"]}",
    ),
    content=(
      #|["\"b\"", "{\"bar\":42,\"foo\":[\"a\",20,\"c\",\"d\"]}", "{\"bar\":42,\"foo\":[\"a\",\"c\",\"d\"]}"]
    ),
  )
}

///|
test "jq_compat_194: map(getpath([2])), map(setpath([2]; 42)), map(delpaths([[2]]" {
  inspect(
    run_jq(
      "map(getpath([2])), map(setpath([2]; 42)), map(delpaths([[2]]))", "[[0], [0,1], [0,1,2]]",
    ),
    content=(
      #|["[null,null,2]", "[[0,null,42],[0,1,42],[0,1,42]]", "[[0],[0,1],[0,1]]"]
    ),
  )
}

///|
test "jq_compat_195: map(delpaths([[0,\"foo\"]]))" {
  inspect(
    run_jq(
      "map(delpaths([[0,\"foo\"]]))", "[[{\"foo\":2, \"x\":1}], [{\"bar\":2}]]",
    ),
    content=(
      #|["[[{\"x\":1}],[{\"bar\":2}]]"]
    ),
  )
}

///|
test "jq_compat_196: [\"foo\",1] as $p | getpath($p), setpath($p; 20), delpaths([$p" {
  inspect(
    run_jq(
      "[\"foo\",1] as $p | getpath($p), setpath($p; 20), delpaths([$p])", "{\"bar\":false}",
    ),
    content=(
      #|["null", "{\"bar\":false,\"foo\":[null,20]}", "{\"bar\":false}"]
    ),
  )
}

///|
test "jq_compat_197: delpaths([[-200]])" {
  inspect(
    run_jq("delpaths([[-200]])", "[1,2,3]"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "jq_compat_198: try delpaths(0) catch ." {
  inspect(
    run_jq("try delpaths(0) catch .", "{}"),
    content=(
      #|["\"Paths must be specified as an array\""]
    ),
  )
}

///|
test "jq_compat_199: del(.), del(empty), del((.foo,.bar,.baz) | .[2,3,0]), del(.f" {
  inspect(
    run_jq(
      "del(.), del(empty), del((.foo,.bar,.baz) | .[2,3,0]), del(.foo[0], .bar[0], .foo, .baz.bar[0].x)",
      "{\"foo\": [0,1,2,3,4], \"bar\": [0,1]}",
    ),
    content=(
      #|["null", "{\"foo\":[0,1,2,3,4],\"bar\":[0,1]}", "{\"foo\":[1,4],\"bar\":[1]}", "{\"bar\":[1]}"]
    ),
  )
}

///|
test "jq_compat_200: del(.[1], .[-6], .[2], .[-3:9])" {
  inspect(
    run_jq("del(.[1], .[-6], .[2], .[-3:9])", "[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]"),
    content=(
      #|["[0,3,5,6,9]"]
    ),
  )
}

///|
test "jq_compat_201: del(.[nan])" {
  inspect(
    run_jq("del(.[nan])", "[1,2,3]"),
    content=(
      #|["[2,3]"]
    ),
  )
}

///|
test "jq_compat_202: del(.[nan,nan])" {
  inspect(
    run_jq("del(.[nan,nan])", "[1,2,3]"),
    content=(
      #|["[3]"]
    ),
  )
}

///|
test "jq_compat_203: setpath([-1]; 1)" {
  inspect(
    run_jq("setpath([-1]; 1)", "[0]"),
    content=(
      #|["[1]"]
    ),
  )
}

///|
test "jq_compat_204: pick(.a.b.c)" {
  inspect(
    run_jq("pick(.a.b.c)", "null"),
    content=(
      #|["{\"a\":{\"b\":{\"c\":null}}}"]
    ),
  )
}

///|
test "jq_compat_205: pick(first)" {
  inspect(
    run_jq("pick(first)", "[1,2]"),
    content=(
      #|["[1]"]
    ),
  )
}

///|
test "jq_compat_206: pick(first|first)" {
  inspect(
    run_jq("pick(first|first)", "[[10,20],30]"),
    content=(
      #|["[[10]]"]
    ),
  )
}

///|
test "jq_compat_207: try pick(last) catch ." {
  inspect(
    run_jq("try pick(last) catch .", "[1,2]"),
    content=(
      #|["[null,2]"]
    ),
  )
}

///|
test "jq_compat_208: .message = \"goodbye\"" {
  inspect(
    run_jq(".message = \"goodbye\"", "{\"message\": \"hello\"}"),
    content=(
      #|["{\"message\":\"goodbye\"}"]
    ),
  )
}

///|
test "jq_compat_209: .foo = .bar" {
  inspect(
    run_jq(".foo = .bar", "{\"bar\":42}"),
    content=(
      #|["{\"bar\":42,\"foo\":42}"]
    ),
  )
}

///|
test "jq_compat_210: .foo |= .+1" {
  inspect(
    run_jq(".foo |= .+1", "{\"foo\": 42}"),
    content=(
      #|["{\"foo\":43}"]
    ),
  )
}

///|
test "jq_compat_211: .[] += 2, .[] *= 2, .[] -= 2, .[] /= 2, .[] %=2" {
  inspect(
    run_jq(".[] += 2, .[] *= 2, .[] -= 2, .[] /= 2, .[] %=2", "[1,3,5]"),
    content=(
      #|["[3,5,7]", "[2,6,10]", "[-1,1,3]", "[0.5,1.5,2.5]", "[1,1,1]"]
    ),
  )
}

///|
test "jq_compat_212: [.[] % 7]" {
  inspect(
    run_jq("[.[] % 7]", "[-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7]"),
    content=(
      #|["[0,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,0]"]
    ),
  )
}

///|
test "jq_compat_213: .foo += .foo" {
  inspect(
    run_jq(".foo += .foo", "{\"foo\":2}"),
    content=(
      #|["{\"foo\":4}"]
    ),
  )
}

///|
test "jq_compat_214: .[0].a |= {\"old\":., \"new\":(.+1)}" {
  inspect(
    run_jq(".[0].a |= {\"old\":., \"new\":(.+1)}", "[{\"a\":1,\"b\":2}]"),
    content=(
      #|["[{\"a\":{\"old\":1,\"new\":2},\"b\":2}]"]
    ),
  )
}

///|
test "jq_compat_215: def inc(x): x |= .+1; inc(.[].a)" {
  inspect(
    run_jq(
      "def inc(x): x |= .+1; inc(.[].a)", "[{\"a\":1,\"b\":2},{\"a\":2,\"b\":4},{\"a\":7,\"b\":8}]",
    ),
    content=(
      #|["[{\"a\":2,\"b\":2},{\"a\":3,\"b\":4},{\"a\":8,\"b\":8}]"]
    ),
  )
}

///|
test "jq_compat_216: (.[] | select(. >= 2)) |= empty" {
  inspect(
    run_jq("(.[] | select(. >= 2)) |= empty", "[1,5,3,0,7]"),
    content=(
      #|["[1,0]"]
    ),
  )
}

///|
test "jq_compat_217: .[] |= select(. % 2 == 0)" {
  inspect(
    run_jq(".[] |= select(. % 2 == 0)", "[0,1,2,3,4,5]"),
    content=(
      #|["[0,2,4]"]
    ),
  )
}

///|
test "jq_compat_218: .foo[1,4,2,3] |= empty" {
  inspect(
    run_jq(".foo[1,4,2,3] |= empty", "{\"foo\":[0,1,2,3,4,5]}"),
    content=(
      #|["{\"foo\":[0,5]}"]
    ),
  )
}

///|
test "jq_compat_219: .[2][3] = 1" {
  inspect(
    run_jq(".[2][3] = 1", "[4]"),
    content=(
      #|["[4,null,[null,null,null,1]]"]
    ),
  )
}

///|
test "jq_compat_220: .foo[2].bar = 1" {
  inspect(
    run_jq(".foo[2].bar = 1", "{\"foo\":[11], \"bar\":42}"),
    content=(
      #|["{\"foo\":[11,null,{\"bar\":1}],\"bar\":42}"]
    ),
  )
}

///|
test "jq_compat_221: def x: .[1,2]; x=10" {
  inspect(
    run_jq("def x: .[1,2]; x=10", "[0,1,2]"),
    content=(
      #|["[0,10,10]"]
    ),
  )
}

///|
test "jq_compat_222: .[] = 1" {
  inspect(
    run_jq(".[] = 1", "[1,null,Infinity,-Infinity,NaN,-NaN]"),
    content=(
      #|["ERROR: invalid JSON input"]
    ),
  )
}

///|
test "jq_compat_223: [.[] | if .foo then \"yep\" else \"nope\" end]" {
  inspect(
    run_jq(
      "[.[] | if .foo then \"yep\" else \"nope\" end]", "[{\"foo\":0},{\"foo\":1},{\"foo\":[]},{\"foo\":true},{\"foo\":false},{\"foo\":null},{\"foo\":\"foo\"},{}]",
    ),
    content=(
      #|["[\"yep\",\"yep\",\"yep\",\"yep\",\"nope\",\"nope\",\"yep\",\"nope\"]"]
    ),
  )
}

///|
test "jq_compat_224: [.[] | if .baz then \"strange\" elif .foo then \"yep\" else \"nop" {
  inspect(
    run_jq(
      "[.[] | if .baz then \"strange\" elif .foo then \"yep\" else \"nope\" end]",
      "[{\"foo\":0},{\"foo\":1},{\"foo\":[]},{\"foo\":true},{\"foo\":false},{\"foo\":null},{\"foo\":\"foo\"},{}]",
    ),
    content=(
      #|["[\"yep\",\"yep\",\"yep\",\"yep\",\"nope\",\"nope\",\"yep\",\"nope\"]"]
    ),
  )
}

///|
test "jq_compat_225: [if 1,null,2 then 3 else 4 end]" {
  inspect(
    run_jq("[if 1,null,2 then 3 else 4 end]", "null"),
    content=(
      #|["[3,4,3]"]
    ),
  )
}

///|
test "jq_compat_226: [if empty then 3 else 4 end]" {
  inspect(
    run_jq("[if empty then 3 else 4 end]", "null"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_227: [if 1 then 3,4 else 5 end]" {
  inspect(
    run_jq("[if 1 then 3,4 else 5 end]", "null"),
    content=(
      #|["[3,4]"]
    ),
  )
}

///|
test "jq_compat_228: [if null then 3 else 5,6 end]" {
  inspect(
    run_jq("[if null then 3 else 5,6 end]", "null"),
    content=(
      #|["[5,6]"]
    ),
  )
}

///|
test "jq_compat_229: [if true then 3 end]" {
  inspect(
    run_jq("[if true then 3 end]", "7"),
    content=(
      #|["[3]"]
    ),
  )
}

///|
test "jq_compat_230: [if false then 3 end]" {
  inspect(
    run_jq("[if false then 3 end]", "7"),
    content=(
      #|["[7]"]
    ),
  )
}

///|
test "jq_compat_231: [if false then 3 else . end]" {
  inspect(
    run_jq("[if false then 3 else . end]", "7"),
    content=(
      #|["[7]"]
    ),
  )
}

///|
test "jq_compat_232: [if false then 3 elif false then 4 end]" {
  inspect(
    run_jq("[if false then 3 elif false then 4 end]", "7"),
    content=(
      #|["[7]"]
    ),
  )
}

///|
test "jq_compat_233: [if false then 3 elif false then 4 else . end]" {
  inspect(
    run_jq("[if false then 3 elif false then 4 else . end]", "7"),
    content=(
      #|["[7]"]
    ),
  )
}

///|
test "jq_compat_234: [-if true then 1 else 2 end]" {
  inspect(
    run_jq("[-if true then 1 else 2 end]", "null"),
    content=(
      #|["[-1]"]
    ),
  )
}

///|
test "jq_compat_235: {x: if true then 1 else 2 end}" {
  inspect(
    run_jq("{x: if true then 1 else 2 end}", "null"),
    content=(
      #|["{\"x\":1}"]
    ),
  )
}

///|
test "jq_compat_236: if true then [.] else . end []" {
  inspect(
    run_jq("if true then [.] else . end []", "null"),
    content=(
      #|["null"]
    ),
  )
}

///|
test "jq_compat_237: [.[] | [.foo[] // .bar]]" {
  inspect(
    run_jq(
      "[.[] | [.foo[] // .bar]]", "[{\"foo\":[1,2], \"bar\": 42}, {\"foo\":[1], \"bar\": null}, {\"foo\":[null,false,3], \"bar\": 18}, {\"foo\":[], \"bar\":42}, {\"foo\": [null,false,null], \"bar\": 41}]",
    ),
    content=(
      #|["[[1,2],[1],[3],[42],[41]]"]
    ),
  )
}

///|
test "jq_compat_238: .[] //= .[0]" {
  inspect(
    run_jq(".[] //= .[0]", "[\"hello\",true,false,[false],null]"),
    content=(
      #|["[\"hello\",true,\"hello\",[false],\"hello\"]"]
    ),
  )
}

///|
test "jq_compat_239: .[] | [.[0] and .[1], .[0] or .[1]]" {
  inspect(
    run_jq(
      ".[] | [.[0] and .[1], .[0] or .[1]]", "[[true,[]], [false,1], [42,null], [null,false]]",
    ),
    content=(
      #|["[true,true]", "[false,true]", "[false,true]", "[false,false]"]
    ),
  )
}

///|
test "jq_compat_240: [.[] | not]" {
  inspect(
    run_jq("[.[] | not]", "[1,0,false,null,true,\"hello\"]"),
    content=(
      #|["[false,false,true,true,false,false]"]
    ),
  )
}

///|
test "jq_compat_241: [10 > 0, 10 > 10, 10 > 20, 10 < 0, 10 < 10, 10 < 20]" {
  inspect(
    run_jq("[10 > 0, 10 > 10, 10 > 20, 10 < 0, 10 < 10, 10 < 20]", "{}"),
    content=(
      #|["[true,false,false,false,false,true]"]
    ),
  )
}

///|
test "jq_compat_242: [10 >= 0, 10 >= 10, 10 >= 20, 10 <= 0, 10 <= 10, 10 <= 20]" {
  inspect(
    run_jq("[10 >= 0, 10 >= 10, 10 >= 20, 10 <= 0, 10 <= 10, 10 <= 20]", "{}"),
    content=(
      #|["[true,true,false,false,true,true]"]
    ),
  )
}

///|
test "jq_compat_243: [ 10 == 10, 10 != 10, 10 != 11, 10 == 11]" {
  inspect(
    run_jq("[ 10 == 10, 10 != 10, 10 != 11, 10 == 11]", "{}"),
    content=(
      #|["[true,false,true,false]"]
    ),
  )
}

///|
test "jq_compat_244: [\"hello\" == \"hello\", \"hello\" != \"hello\", \"hello\" == \"world\"," {
  inspect(
    run_jq(
      "[\"hello\" == \"hello\", \"hello\" != \"hello\", \"hello\" == \"world\", \"hello\" != \"world\" ]",
      "{}",
    ),
    content=(
      #|["[true,false,false,true]"]
    ),
  )
}

///|
test "jq_compat_245: [[1,2,3] == [1,2,3], [1,2,3] != [1,2,3], [1,2,3] == [4,5,6]," {
  inspect(
    run_jq(
      "[[1,2,3] == [1,2,3], [1,2,3] != [1,2,3], [1,2,3] == [4,5,6], [1,2,3] != [4,5,6]]",
      "{}",
    ),
    content=(
      #|["[true,false,false,true]"]
    ),
  )
}

///|
test "jq_compat_246: [{\"foo\":42} == {\"foo\":42},{\"foo\":42} != {\"foo\":42}, {\"foo\":4" {
  inspect(
    run_jq(
      "[{\"foo\":42} == {\"foo\":42},{\"foo\":42} != {\"foo\":42}, {\"foo\":42} != {\"bar\":42}, {\"foo\":42} == {\"bar\":42}]",
      "{}",
    ),
    content=(
      #|["[true,false,true,false]"]
    ),
  )
}

///|
test "jq_compat_247: [{\"foo\":[1,2,{\"bar\":18},\"world\"]} == {\"foo\":[1,2,{\"bar\":18}," {
  inspect(
    run_jq(
      "[{\"foo\":[1,2,{\"bar\":18},\"world\"]} == {\"foo\":[1,2,{\"bar\":18},\"world\"]},{\"foo\":[1,2,{\"bar\":18},\"world\"]} == {\"foo\":[1,2,{\"bar\":19},\"world\"]}]",
      "{}",
    ),
    content=(
      #|["[true,false]"]
    ),
  )
}

///|
test "jq_compat_248: [(\"foo\" | contains(\"foo\")), (\"foobar\" | contains(\"foo\")), (\"" {
  inspect(
    run_jq(
      "[(\"foo\" | contains(\"foo\")), (\"foobar\" | contains(\"foo\")), (\"foo\" | contains(\"foobar\"))]",
      "{}",
    ),
    content=(
      #|["[true,true,false]"]
    ),
  )
}

///|
test "jq_compat_249: [contains(\"\"), contains(\"\\u0000\")]" {
  inspect(
    run_jq("[contains(\"\"), contains(\"\\u0000\")]", "\"\\u0000\""),
    content=(
      #|["[true,false]"]
    ),
  )
}

///|
test "jq_compat_250: [contains(\"\"), contains(\"a\"), contains(\"ab\"), contains(\"c\")," {
  inspect(
    run_jq(
      "[contains(\"\"), contains(\"a\"), contains(\"ab\"), contains(\"c\"), contains(\"d\")]",
      "\"ab\\u0000cd\"",
    ),
    content=(
      #|["[true,true,true,true,true]"]
    ),
  )
}

///|
test "jq_compat_251: [contains(\"cd\"), contains(\"b\\u0000\"), contains(\"ab\\u0000\")]" {
  inspect(
    run_jq(
      "[contains(\"cd\"), contains(\"b\\u0000\"), contains(\"ab\\u0000\")]", "\"ab\\u0000cd\"",
    ),
    content=(
      #|["[true,false,false]"]
    ),
  )
}

///|
test "jq_compat_252: [contains(\"b\\u0000c\"), contains(\"b\\u0000cd\"), contains(\"b\\u0" {
  inspect(
    run_jq(
      "[contains(\"b\\u0000c\"), contains(\"b\\u0000cd\"), contains(\"b\\u0000cd\")]",
      "\"ab\\u0000cd\"",
    ),
    content=(
      #|["[false,false,false]"]
    ),
  )
}

///|
test "jq_compat_253: [contains(\"@\"), contains(\"\\u0000@\"), contains(\"\\u0000what\")]" {
  inspect(
    run_jq(
      "[contains(\"@\"), contains(\"\\u0000@\"), contains(\"\\u0000what\")]", "\"ab\\u0000cd\"",
    ),
    content=(
      #|["[false,false,false]"]
    ),
  )
}

///|
test "jq_compat_254: [.[]|try if . == 0 then error(\"foo\") elif . == 1 then .a eli" {
  inspect(
    run_jq(
      "[.[]|try if . == 0 then error(\"foo\") elif . == 1 then .a elif . == 2 then empty else . end catch .]",
      "[0,1,2,3]",
    ),
    content=(
      #|["[\"foo\",\"Cannot index number with string \\\"a\\\"\",3]"]
    ),
  )
}

///|
test "jq_compat_255: [.[]|(.a, .a)?]" {
  inspect(
    run_jq("[.[]|(.a, .a)?]", "[null,true,{\"a\":1}]"),
    content=(
      #|["[null,null,1,1]"]
    ),
  )
}

///|
test "jq_compat_256: [[.[]|[.a,.a]]?]" {
  inspect(
    run_jq("[[.[]|[.a,.a]]?]", "[null,true,{\"a\":1}]"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_257: [if error then 1 else 2 end?]" {
  inspect(
    run_jq("[if error then 1 else 2 end?]", "\"foo\""),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_258: try error(0) // 1" {
  inspect(
    run_jq("try error(0) // 1", "null"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_259: 1, try error(2), 3" {
  inspect(
    run_jq("1, try error(2), 3", "null"),
    content=(
      #|["1", "3"]
    ),
  )
}

///|
test "jq_compat_260: 1 + try 2 catch 3 + 4" {
  inspect(
    run_jq("1 + try 2 catch 3 + 4", "null"),
    content=(
      #|["7"]
    ),
  )
}

///|
test "jq_compat_261: [-try .]" {
  inspect(
    run_jq("[-try .]", "1"),
    content=(
      #|["[-1]"]
    ),
  )
}

///|
test "jq_compat_262: try -.? catch ." {
  inspect(
    run_jq("try -.? catch .", "\"foo\""),
    content=(
      #|["\"string (\\\"foo\\\") cannot be negated\""]
    ),
  )
}

///|
test "jq_compat_263: {x: try 1, y: try error catch 2, z: if true then 3 end}" {
  inspect(
    run_jq("{x: try 1, y: try error catch 2, z: if true then 3 end}", "null"),
    content=(
      #|["{\"x\":1,\"y\":2,\"z\":3}"]
    ),
  )
}

///|
test "jq_compat_264: {x: 1 + 2, y: false or true, z: null // 3}" {
  inspect(
    run_jq("{x: 1 + 2, y: false or true, z: null // 3}", "null"),
    content=(
      #|["{\"x\":3,\"y\":true,\"z\":3}"]
    ),
  )
}

///|
test "jq_compat_265: .[] | try error catch ." {
  inspect(
    run_jq(".[] | try error catch .", "[1,null,2]"),
    content=(
      #|["1", "null", "2"]
    ),
  )
}

///|
test "jq_compat_266: try error(\"\\($__loc__)\") catch ." {
  inspect(
    run_jq("try error(\"\\($__loc__)\") catch .", "null"),
    content=(
      #|["\"{\\\"file\\\":\\\"<top-level>\\\",\\\"line\\\":1}\""]
    ),
  )
}

///|
test "jq_compat_267: [.[]|startswith(\"foo\")]" {
  inspect(
    run_jq(
      "[.[]|startswith(\"foo\")]", "[\"fo\", \"foo\", \"barfoo\", \"foobar\", \"barfoob\"]",
    ),
    content=(
      #|["[false,true,false,true,false]"]
    ),
  )
}

///|
test "jq_compat_268: [.[]|endswith(\"foo\")]" {
  inspect(
    run_jq(
      "[.[]|endswith(\"foo\")]", "[\"fo\", \"foo\", \"barfoo\", \"foobar\", \"barfoob\"]",
    ),
    content=(
      #|["[false,true,true,false,false]"]
    ),
  )
}

///|
test "jq_compat_269: [.[] | split(\", \")]" {
  inspect(
    run_jq(
      "[.[] | split(\", \")]", "[\"a,b, c, d, e,f\",\", a,b, c, d, e,f, \"]",
    ),
    content=(
      #|["[[\"a,b\",\"c\",\"d\",\"e,f\"],[\"\",\"a,b\",\"c\",\"d\",\"e,f\",\"\"]]"]
    ),
  )
}

///|
test "jq_compat_270: split(\"\")" {
  inspect(
    run_jq("split(\"\")", "\"abc\""),
    content=(
      #|["[\"a\",\"b\",\"c\"]"]
    ),
  )
}

///|
test "jq_compat_271: [.[]|ltrimstr(\"foo\")]" {
  inspect(
    run_jq(
      "[.[]|ltrimstr(\"foo\")]", "[\"fo\", \"foo\", \"barfoo\", \"foobar\", \"afoo\"]",
    ),
    content=(
      #|["[\"fo\",\"\",\"barfoo\",\"bar\",\"afoo\"]"]
    ),
  )
}

///|
test "jq_compat_272: [.[]|rtrimstr(\"foo\")]" {
  inspect(
    run_jq(
      "[.[]|rtrimstr(\"foo\")]", "[\"fo\", \"foo\", \"barfoo\", \"foobar\", \"foob\"]",
    ),
    content=(
      #|["[\"fo\",\"\",\"bar\",\"foobar\",\"foob\"]"]
    ),
  )
}

///|
test "jq_compat_273: [.[]|trimstr(\"foo\")]" {
  inspect(
    run_jq(
      "[.[]|trimstr(\"foo\")]", "[\"fo\", \"foo\", \"barfoo\", \"foobarfoo\", \"foob\"]",
    ),
    content=(
      #|["[\"fo\",\"\",\"bar\",\"bar\",\"b\"]"]
    ),
  )
}

///|
test "jq_compat_274: [.[]|ltrimstr(\"\")]" {
  inspect(
    run_jq("[.[]|ltrimstr(\"\")]", "[\"a\", \"xx\", \"\"]"),
    content=(
      #|["[\"a\",\"xx\",\"\"]"]
    ),
  )
}

///|
test "jq_compat_275: [.[]|rtrimstr(\"\")]" {
  inspect(
    run_jq("[.[]|rtrimstr(\"\")]", "[\"a\", \"xx\", \"\"]"),
    content=(
      #|["[\"a\",\"xx\",\"\"]"]
    ),
  )
}

///|
test "jq_compat_276: [.[]|trimstr(\"\")]" {
  inspect(
    run_jq("[.[]|trimstr(\"\")]", "[\"a\", \"xx\", \"\"]"),
    content=(
      #|["[\"a\",\"xx\",\"\"]"]
    ),
  )
}

///|
test "jq_compat_277: [(index(\",\"), rindex(\",\")), indices(\",\")]" {
  inspect(
    run_jq(
      "[(index(\",\"), rindex(\",\")), indices(\",\")]", "\"a,bc,def,ghij,klmno\"",
    ),
    content=(
      #|["[1,13,[1,4,8,13]]"]
    ),
  )
}

///|
test "jq_compat_278: [ index(\"aba\"), rindex(\"aba\"), indices(\"aba\") ]" {
  inspect(
    run_jq(
      "[ index(\"aba\"), rindex(\"aba\"), indices(\"aba\") ]", "\"xababababax\"",
    ),
    content=(
      #|["[1,7,[1,3,5,7]]"]
    ),
  )
}

///|
test "jq_compat_279: map(trim), map(ltrim), map(rtrim)" {
  inspect(
    run_jq(
      "map(trim), map(ltrim), map(rtrim)", "[\" \\n\\t\\r\\f\\u000b\", \"\",\"  \", \"a\", \" a \", \"abc\", \"  abc  \", \"  abc\", \"abc  \"]",
    ),
    content=(
      #|["[\"\",\"\",\"\",\"a\",\"a\",\"abc\",\"abc\",\"abc\",\"abc\"]", "[\"\",\"\",\"\",\"a\",\"a \",\"abc\",\"abc  \",\"abc\",\"abc  \"]", "[\"\",\"\",\"\",\"a\",\" a\",\"abc\",\"  abc\",\"  abc\",\"abc\"]"]
    ),
  )
}

///|
test "jq_compat_280: trim, ltrim, rtrim" {
  inspect(
    run_jq(
      "trim, ltrim, rtrim", "\"\\u0009\\u000A\\u000B\\u000C\\u000D\\u0020\\u0085\\u00A0\\u1680\\u2000\\u2001\\u2002\\u2003\\u2004\\u2005\\u2006\\u2007\\u2008\\u2009\\u200A\\u2028\\u2029\\u202F\\u205F\\u3000abc\\u0009\\u000A\\u000B\\u000C\\u000D\\u0020\\u0085\\u00A0\\u1680\\u2000\\u2001\\u2002\\u2003\\u2004\\u2005\\u2006\\u2007\\u2008\\u2009\\u200A\\u2028\\u2029\\u202F\\u205F\\u3000\"",
    ),
    content=(
      #|["\"abc\"", "\"abc\\t\\n\\u000b\\f\\r                  　\"", "\"\\t\\n\\u000b\\f\\r                  　abc\""]
    ),
  )
}

///|
test "jq_compat_281: try trim catch ., try ltrim catch ., try rtrim catch ." {
  inspect(
    run_jq("try trim catch ., try ltrim catch ., try rtrim catch .", "123"),
    content=(
      #|["\"trim input must be a string\"", "\"trim input must be a string\"", "\"trim input must be a string\""]
    ),
  )
}

///|
test "jq_compat_282: indices(1)" {
  inspect(
    run_jq("indices(1)", "[0,1,1,2,3,4,1,5]"),
    content=(
      #|["[1,2,6]"]
    ),
  )
}

///|
test "jq_compat_283: indices([1,2])" {
  inspect(
    run_jq("indices([1,2])", "[0,1,2,3,1,4,2,5,1,2,6,7]"),
    content=(
      #|["[1,8]"]
    ),
  )
}

///|
test "jq_compat_284: indices([1,2])" {
  inspect(
    run_jq("indices([1,2])", "[1]"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_285: indices(\", \")" {
  inspect(
    run_jq("indices(\", \")", "\"a,b, cd,e, fgh, ijkl\""),
    content=(
      #|["[3,9,14]"]
    ),
  )
}

///|
test "jq_compat_286: index(\"!\")" {
  inspect(
    run_jq("index(\"!\")", "\"здравствуй мир!\""),
    content=(
      #|["14"]
    ),
  )
}

///|
test "jq_compat_287: .[:rindex(\"x\")]" {
  inspect(
    run_jq(".[:rindex(\"x\")]", "\"正xyz\""),
    content=(
      #|["\"正\""]
    ),
  )
}

///|
test "jq_compat_288: indices(\"o\")" {
  inspect(
    run_jq("indices(\"o\")", "\"🇬🇧oo\""),
    content=(
      #|["[2,3]"]
    ),
  )
}

///|
test "jq_compat_289: indices(\"o\")" {
  inspect(
    run_jq("indices(\"o\")", "\"ƒoo\""),
    content=(
      #|["[1,2]"]
    ),
  )
}

///|
test "jq_compat_290: [.[]|split(\",\")]" {
  inspect(
    run_jq(
      "[.[]|split(\",\")]", "[\"a, bc, def, ghij, jklmn, a,b, c,d, e,f\", \"a,b,c,d, e,f,g,h\"]",
    ),
    content=(
      #|["[[\"a\",\" bc\",\" def\",\" ghij\",\" jklmn\",\" a\",\"b\",\" c\",\"d\",\" e\",\"f\"],[\"a\",\"b\",\"c\",\"d\",\" e\",\"f\",\"g\",\"h\"]]"]
    ),
  )
}

///|
test "jq_compat_291: [.[]|split(\", \")]" {
  inspect(
    run_jq(
      "[.[]|split(\", \")]", "[\"a, bc, def, ghij, jklmn, a,b, c,d, e,f\", \"a,b,c,d, e,f,g,h\"]",
    ),
    content=(
      #|["[[\"a\",\"bc\",\"def\",\"ghij\",\"jklmn\",\"a,b\",\"c,d\",\"e,f\"],[\"a,b,c,d\",\"e,f,g,h\"]]"]
    ),
  )
}

///|
test "jq_compat_292: [.[] * 3]" {
  inspect(
    run_jq("[.[] * 3]", "[\"a\", \"ab\", \"abc\"]"),
    content=(
      #|["[\"aaa\",\"ababab\",\"abcabcabc\"]"]
    ),
  )
}

///|
test "jq_compat_293: [.[] * \"abc\"]" {
  inspect(
    run_jq("[.[] * \"abc\"]", "[-1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 3.7, 10.0]"),
    content=(
      #|["[null,null,\"\",\"\",\"abc\",\"abc\",\"abcabcabc\",\"abcabcabcabcabcabcabcabcabcabc\"]"]
    ),
  )
}

///|
test "jq_compat_294: [. * (nan,-nan)]" {
  inspect(
    run_jq("[. * (nan,-nan)]", "\"abc\""),
    content=(
      #|["[null,null]"]
    ),
  )
}

///|
test "jq_compat_295: . * 100000 | [.[:10],.[-10:]]" {
  inspect(
    run_jq(". * 100000 | [.[:10],.[-10:]]", "\"abc\""),
    content=(
      #|["[\"abcabcabca\",\"cabcabcabc\"]"]
    ),
  )
}

///|
test "jq_compat_296: . * 1000000000" {
  inspect(
    run_jq(". * 1000000000", "\"\""),
    content=(
      #|["\"\""]
    ),
  )
}

///|
test "jq_compat_297: [.[] / \",\"]" {
  inspect(
    run_jq(
      "[.[] / \",\"]", "[\"a, bc, def, ghij, jklmn, a,b, c,d, e,f\", \"a,b,c,d, e,f,g,h\"]",
    ),
    content=(
      #|["[[\"a\",\" bc\",\" def\",\" ghij\",\" jklmn\",\" a\",\"b\",\" c\",\"d\",\" e\",\"f\"],[\"a\",\"b\",\"c\",\"d\",\" e\",\"f\",\"g\",\"h\"]]"]
    ),
  )
}

///|
test "jq_compat_298: [.[] / \", \"]" {
  inspect(
    run_jq(
      "[.[] / \", \"]", "[\"a, bc, def, ghij, jklmn, a,b, c,d, e,f\", \"a,b,c,d, e,f,g,h\"]",
    ),
    content=(
      #|["[[\"a\",\"bc\",\"def\",\"ghij\",\"jklmn\",\"a,b\",\"c,d\",\"e,f\"],[\"a,b,c,d\",\"e,f,g,h\"]]"]
    ),
  )
}

///|
test "jq_compat_299: map(.[1] as $needle | .[0] | contains($needle))" {
  inspect(
    run_jq(
      "map(.[1] as $needle | .[0] | contains($needle))", "[[[],[]], [[1,2,3], [1,2]], [[1,2,3], [3,1]], [[1,2,3], [4]], [[1,2,3], [1,4]]]",
    ),
    content=(
      #|["[true,true,true,false,false]"]
    ),
  )
}

///|
test "jq_compat_300: map(.[1] as $needle | .[0] | contains($needle))" {
  inspect(
    run_jq(
      "map(.[1] as $needle | .[0] | contains($needle))", "[[[\"foobar\", \"foobaz\"], [\"baz\", \"bar\"]], [[\"foobar\", \"foobaz\"], [\"foo\"]], [[\"foobar\", \"foobaz\"], [\"blap\"]]]",
    ),
    content=(
      #|["[true,true,false]"]
    ),
  )
}

///|
test "jq_compat_301: [({foo: 12, bar:13} | contains({foo: 12})), ({foo: 12} | con" {
  inspect(
    run_jq(
      "[({foo: 12, bar:13} | contains({foo: 12})), ({foo: 12} | contains({})), ({foo: 12, bar:13} | contains({baz:14}))]",
      "{}",
    ),
    content=(
      #|["[true,true,false]"]
    ),
  )
}

///|
test "jq_compat_302: {foo: {baz: 12, blap: {bar: 13}}, bar: 14} | contains({bar: " {
  inspect(
    run_jq(
      "{foo: {baz: 12, blap: {bar: 13}}, bar: 14} | contains({bar: 14, foo: {blap: {}}})",
      "{}",
    ),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_303: {foo: {baz: 12, blap: {bar: 13}}, bar: 14} | contains({bar: " {
  inspect(
    run_jq(
      "{foo: {baz: 12, blap: {bar: 13}}, bar: 14} | contains({bar: 14, foo: {blap: {bar: 14}}})",
      "{}",
    ),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_304: sort" {
  inspect(
    run_jq(
      "sort", "[42,[2,5,3,11],10,{\"a\":42,\"b\":2},{\"a\":42},true,2,[2,6],\"hello\",null,[2,5,6],{\"a\":[],\"b\":1},\"abc\",\"ab\",[3,10],{},false,\"abcd\",null]",
    ),
    content=(
      #|["[null,null,false,true,2,10,42,\"ab\",\"abc\",\"abcd\",\"hello\",[2,5,3,11],[2,5,6],[2,6],[3,10],{},{\"a\":42},{\"a\":42,\"b\":2},{\"a\":[],\"b\":1}]"]
    ),
  )
}

///|
test "jq_compat_305: (sort_by(.b) | sort_by(.a)), sort_by(.a, .b), sort_by(.b, .c" {
  inspect(
    run_jq(
      "(sort_by(.b) | sort_by(.a)), sort_by(.a, .b), sort_by(.b, .c), group_by(.b), group_by(.a + .b - .c == 2)",
      "[{\"a\": 1, \"b\": 4, \"c\": 14}, {\"a\": 4, \"b\": 1, \"c\": 3}, {\"a\": 1, \"b\": 4, \"c\": 3}, {\"a\": 0, \"b\": 2, \"c\": 43}]",
    ),
    content=(
      #|["[{\"a\":0,\"b\":2,\"c\":43},{\"a\":1,\"b\":4,\"c\":14},{\"a\":1,\"b\":4,\"c\":3},{\"a\":4,\"b\":1,\"c\":3}]", "[{\"a\":0,\"b\":2,\"c\":43},{\"a\":1,\"b\":4,\"c\":14},{\"a\":1,\"b\":4,\"c\":3},{\"a\":4,\"b\":1,\"c\":3}]", "[{\"a\":4,\"b\":1,\"c\":3},{\"a\":0,\"b\":2,\"c\":43},{\"a\":1,\"b\":4,\"c\":3},{\"a\":1,\"b\":4,\"c\":14}]", "[[{\"a\":4,\"b\":1,\"c\":3}],[{\"a\":0,\"b\":2,\"c\":43}],[{\"a\":1,\"b\":4,\"c\":14},{\"a\":1,\"b\":4,\"c\":3}]]", "[[{\"a\":1,\"b\":4,\"c\":14},{\"a\":0,\"b\":2,\"c\":43}],[{\"a\":4,\"b\":1,\"c\":3},{\"a\":1,\"b\":4,\"c\":3}]]"]
    ),
  )
}

///|
test "jq_compat_306: unique" {
  inspect(
    run_jq("unique", "[1,2,5,3,5,3,1,3]"),
    content=(
      #|["[1,2,3,5]"]
    ),
  )
}

///|
test "jq_compat_307: unique" {
  inspect(
    run_jq("unique", "[]"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_308: [min, max, min_by(.[1]), max_by(.[1]), min_by(.[2]), max_by(" {
  inspect(
    run_jq(
      "[min, max, min_by(.[1]), max_by(.[1]), min_by(.[2]), max_by(.[2])]", "[[4,2,\"a\"],[3,1,\"a\"],[2,4,\"a\"],[1,3,\"a\"]]",
    ),
    content=(
      #|["[[1,3,\"a\"],[4,2,\"a\"],[3,1,\"a\"],[2,4,\"a\"],[4,2,\"a\"],[4,2,\"a\"]]"]
    ),
  )
}

///|
test "jq_compat_309: [min,max,min_by(.),max_by(.)]" {
  inspect(
    run_jq("[min,max,min_by(.),max_by(.)]", "[]"),
    content=(
      #|["[null,null,null,null]"]
    ),
  )
}

///|
test "jq_compat_310: .foo[.baz]" {
  inspect(
    run_jq(".foo[.baz]", "{\"foo\":{\"bar\":4},\"baz\":\"bar\"}"),
    content=(
      #|["4"]
    ),
  )
}

///|
test "jq_compat_311: .[] | .error = \"no, it's OK\"" {
  inspect(
    run_jq(".[] | .error = \"no, it's OK\"", "[{\"error\":true}]"),
    content=(
      #|["{\"error\":\"no, it's OK\"}"]
    ),
  )
}

///|
test "jq_compat_312: [{a:1}] | .[] | .a=999" {
  inspect(
    run_jq("[{a:1}] | .[] | .a=999", "null"),
    content=(
      #|["{\"a\":999}"]
    ),
  )
}

///|
test "jq_compat_313: to_entries" {
  inspect(
    run_jq("to_entries", "{\"a\": 1, \"b\": 2}"),
    content=(
      #|["[{\"key\":\"a\",\"value\":1},{\"key\":\"b\",\"value\":2}]"]
    ),
  )
}

///|
test "jq_compat_314: from_entries" {
  inspect(
    run_jq(
      "from_entries", "[{\"key\":\"a\", \"value\":1}, {\"Key\":\"b\", \"Value\":2}, {\"name\":\"c\", \"value\":3}, {\"Name\":\"d\", \"Value\":4}]",
    ),
    content=(
      #|["{\"a\":1,\"b\":2,\"c\":3,\"d\":4}"]
    ),
  )
}

///|
test "jq_compat_315: with_entries(.key |= \"KEY_\" + .)" {
  inspect(
    run_jq("with_entries(.key |= \"KEY_\" + .)", "{\"a\": 1, \"b\": 2}"),
    content=(
      #|["{\"KEY_a\":1,\"KEY_b\":2}"]
    ),
  )
}

///|
test "jq_compat_316: map(has(\"foo\"))" {
  inspect(
    run_jq("map(has(\"foo\"))", "[{\"foo\": 42}, {}]"),
    content=(
      #|["[true,false]"]
    ),
  )
}

///|
test "jq_compat_317: map(has(2))" {
  inspect(
    run_jq("map(has(2))", "[[0,1], [\"a\",\"b\",\"c\"]]"),
    content=(
      #|["[false,true]"]
    ),
  )
}

///|
test "jq_compat_318: has(nan)" {
  inspect(
    run_jq("has(nan)", "[0,1,2]"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_319: keys" {
  inspect(
    run_jq("keys", "[42,3,35]"),
    content=(
      #|["[0,1,2]"]
    ),
  )
}

///|
test "jq_compat_320: [][.]" {
  inspect(
    run_jq("[][.]", "1000000000000000000"),
    content=(
      #|["null"]
    ),
  )
}

///|
test "jq_compat_321: map([1,2][0:.])" {
  inspect(
    run_jq("map([1,2][0:.])", "[-1, 1, 2, 3, 1000000000000000000]"),
    content=(
      #|["[[1],[1],[1,2],[1,2],[1,2]]"]
    ),
  )
}

///|
test "jq_compat_322: {\"k\": {\"a\": 1, \"b\": 2}} * ." {
  inspect(
    run_jq("{\"k\": {\"a\": 1, \"b\": 2}} * .", "{\"k\": {\"a\": 0,\"c\": 3}}"),
    content=(
      #|["{\"k\":{\"a\":0,\"b\":2,\"c\":3}}"]
    ),
  )
}

///|
test "jq_compat_323: {\"k\": {\"a\": 1, \"b\": 2}, \"hello\": {\"x\": 1}} * ." {
  inspect(
    run_jq(
      "{\"k\": {\"a\": 1, \"b\": 2}, \"hello\": {\"x\": 1}} * .", "{\"k\": {\"a\": 0,\"c\": 3}, \"hello\": 1}",
    ),
    content=(
      #|["{\"k\":{\"a\":0,\"b\":2,\"c\":3},\"hello\":1}"]
    ),
  )
}

///|
test "jq_compat_324: {\"k\": {\"a\": 1, \"b\": 2}, \"hello\": 1} * ." {
  inspect(
    run_jq(
      "{\"k\": {\"a\": 1, \"b\": 2}, \"hello\": 1} * .", "{\"k\": {\"a\": 0,\"c\": 3}, \"hello\": {\"x\": 1}}",
    ),
    content=(
      #|["{\"k\":{\"a\":0,\"b\":2,\"c\":3},\"hello\":{\"x\":1}}"]
    ),
  )
}

///|
test "jq_compat_325: {\"a\": {\"b\": 1}, \"c\": {\"d\": 2}, \"e\": 5} * ." {
  inspect(
    run_jq(
      "{\"a\": {\"b\": 1}, \"c\": {\"d\": 2}, \"e\": 5} * .", "{\"a\": {\"b\": 2}, \"c\": {\"d\": 3, \"f\": 9}}",
    ),
    content=(
      #|["{\"a\":{\"b\":2},\"c\":{\"d\":3,\"f\":9},\"e\":5}"]
    ),
  )
}

///|
test "jq_compat_326: [.[]|arrays]" {
  inspect(
    run_jq("[.[]|arrays]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[[],[3,[]]]"]
    ),
  )
}

///|
test "jq_compat_327: [.[]|objects]" {
  inspect(
    run_jq("[.[]|objects]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[{}]"]
    ),
  )
}

///|
test "jq_compat_328: [.[]|iterables]" {
  inspect(
    run_jq("[.[]|iterables]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[[],[3,[]],{}]"]
    ),
  )
}

///|
test "jq_compat_329: [.[]|scalars]" {
  inspect(
    run_jq("[.[]|scalars]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[1,2,\"foo\",true,false,null]"]
    ),
  )
}

///|
test "jq_compat_330: [.[]|values]" {
  inspect(
    run_jq("[.[]|values]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[1,2,\"foo\",[],[3,[]],{},true,false]"]
    ),
  )
}

///|
test "jq_compat_331: [.[]|booleans]" {
  inspect(
    run_jq("[.[]|booleans]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[true,false]"]
    ),
  )
}

///|
test "jq_compat_332: [.[]|nulls]" {
  inspect(
    run_jq("[.[]|nulls]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[null]"]
    ),
  )
}

///|
test "jq_compat_333: flatten" {
  inspect(
    run_jq("flatten", "[0, [1], [[2]], [[[3]]]]"),
    content=(
      #|["[0,1,2,3]"]
    ),
  )
}

///|
test "jq_compat_334: try flatten(-1) catch ." {
  inspect(
    run_jq("try flatten(-1) catch .", "[0, [1], [[2]], [[[3]]]]"),
    content=(
      #|["\"flatten depth must not be negative\""]
    ),
  )
}

///|
test "jq_compat_335: transpose" {
  inspect(
    run_jq("transpose", "[[1], [2,3]]"),
    content=(
      #|["[[1,2],[null,3]]"]
    ),
  )
}

///|
test "jq_compat_336: transpose" {
  inspect(
    run_jq("transpose", "[]"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_337: ascii_upcase" {
  inspect(
    run_jq("ascii_upcase", "\"useful but not for é\""),
    content=(
      #|["\"USEFUL BUT NOT FOR é\""]
    ),
  )
}

///|
test "jq_compat_338: bsearch(0,1,2,3,4)" {
  inspect(
    run_jq("bsearch(0,1,2,3,4)", "[1,2,3]"),
    content=(
      #|["-1", "0", "1", "2", "-4"]
    ),
  )
}

///|
test "jq_compat_339: bsearch({x:1})" {
  inspect(
    run_jq("bsearch({x:1})", "[{ \"x\": 0 },{ \"x\": 1 },{ \"x\": 2 }]"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_340: try [\"OK\", bsearch(0)] catch [\"KO\",.]" {
  inspect(
    run_jq("try [\"OK\", bsearch(0)] catch [\"KO\",.]", "\"aa\""),
    content=(
      #|["[\"KO\",\"string (\\\"aa\\\") cannot be searched from\"]"]
    ),
  )
}

///|
test "jq_compat_341: try strflocaltime(\"%Y-%m-%dT%H:%M:%SZ\") catch ." {
  inspect(
    run_jq(
      "try strflocaltime(\"%Y-%m-%dT%H:%M:%SZ\") catch .", "[\"a\",1,2,3,4,5,6,7]",
    ),
    content=(
      #|["\"unknown function: strflocaltime\""]
    ),
  )
}

///|
test "jq_compat_342: try [\"OK\", strflocaltime({})] catch [\"KO\", .]" {
  inspect(
    run_jq("try [\"OK\", strflocaltime({})] catch [\"KO\", .]", "0"),
    content=(
      #|["[\"KO\",\"unknown function: strflocaltime\"]"]
    ),
  )
}

///|
test "jq_compat_343: modulemeta | .deps | length" {
  inspect(
    run_jq("modulemeta | .deps | length", "\"c\""),
    content=(
      #|["ERROR: unknown function: modulemeta"]
    ),
  )
}

///|
test "jq_compat_344: modulemeta | .defs | length" {
  inspect(
    run_jq("modulemeta | .defs | length", "\"c\""),
    content=(
      #|["ERROR: unknown function: modulemeta"]
    ),
  )
}

///|
test "jq_compat_345: %%FAIL IGNORE MSG" {
  inspect(
    run_jq("%%FAIL IGNORE MSG", "import \"syntaxerror\" as e; ."),
    content=(
      #|["ERROR: invalid JSON input"]
    ),
  )
}

///|
test "jq_compat_346: try -. catch ." {
  inspect(
    run_jq("try -. catch .", "\"very-long-long-long-long-string\""),
    content=(
      #|["\"string (\\\"very-long-...) cannot be negated\""]
    ),
  )
}

///|
test "jq_compat_347: \"x\" * range(0; 12; 2) + \"☆\" * 8 | try -. catch ." {
  inspect(
    run_jq("\"x\" * range(0; 12; 2) + \"☆\" * 8 | try -. catch .", "null"),
    content=(
      #|["\"string (\\\"☆☆☆☆☆☆☆☆\\\") cannot be negated\"", "\"string (\\\"xx☆☆☆☆☆☆☆☆\\\") cannot be negated\"", "\"string (\\\"xxxx☆☆☆☆☆☆...) cannot be negated\"", "\"string (\\\"xxxxxx☆☆☆☆...) cannot be negated\"", "\"string (\\\"xxxxxxxx☆☆...) cannot be negated\"", "\"string (\\\"xxxxxxxxxx...) cannot be negated\""]
    ),
  )
}

///|
test "jq_compat_348: join(\",\")" {
  inspect(
    run_jq("join(\",\")", "[\"1\",2,true,false,3.4]"),
    content=(
      #|["\"1,2,true,false,3.4\""]
    ),
  )
}

///|
test "jq_compat_349: .[] | join(\",\")" {
  inspect(
    run_jq(".[] | join(\",\")", "[[], [null], [null,null], [null,null,null]]"),
    content=(
      #|["\"\"", "\"\"", "\",\"", "\",,\""]
    ),
  )
}

///|
test "jq_compat_350: .[] | join(\",\")" {
  inspect(
    run_jq(".[] | join(\",\")", "[[\"a\",null], [null,\"a\"]]"),
    content=(
      #|["\"a,\"", "\",a\""]
    ),
  )
}

///|
test "jq_compat_351: try join(\",\") catch ." {
  inspect(
    run_jq(
      "try join(\",\") catch .", "[\"1\",\"2\",{\"a\":{\"b\":{\"c\":33}}}]",
    ),
    content=(
      #|["\"string (\\\"1,2,\\\") and object ({\\\"a\\\":{\\\"b\\\":{\\\"c\\\":33}}}) cannot be added\""]
    ),
  )
}

///|
test "jq_compat_352: try join(\",\") catch ." {
  inspect(
    run_jq("try join(\",\") catch .", "[\"1\",\"2\",[3,4,5]]"),
    content=(
      #|["\"string (\\\"1,2,\\\") and array ([3,4,5]) cannot be added\""]
    ),
  )
}

///|
test "jq_compat_353: [range(-52;52;1)] as $powers | [$powers[]|pow(2;.)|log2|roun" {
  inspect(
    run_jq(
      "[range(-52;52;1)] as $powers | [$powers[]|pow(2;.)|log2|round] == $powers",
      "null",
    ),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_354: INDEX(range(5)|[., \"foo\\(.)\"]; .[0])" {
  inspect(
    run_jq("INDEX(range(5)|[., \"foo\\(.)\"]; .[0])", "null"),
    content=(
      #|["{\"0\":[0,\"foo0\"],\"1\":[1,\"foo1\"],\"2\":[2,\"foo2\"],\"3\":[3,\"foo3\"],\"4\":[4,\"foo4\"]}"]
    ),
  )
}

///|
test "jq_compat_355: JOIN({\"0\":[0,\"abc\"],\"1\":[1,\"bcd\"],\"2\":[2,\"def\"],\"3\":[3,\"efg\"" {
  inspect(
    run_jq(
      "JOIN({\"0\":[0,\"abc\"],\"1\":[1,\"bcd\"],\"2\":[2,\"def\"],\"3\":[3,\"efg\"],\"4\":[4,\"fgh\"]}; .[0]|tostring)",
      "[[5,\"foo\"],[3,\"bar\"],[1,\"foobar\"]]",
    ),
    content=(
      #|["ERROR: unknown function: JOIN"]
    ),
  )
}

///|
test "jq_compat_356: range(5;10)|IN(range(10))" {
  inspect(
    run_jq("range(5;10)|IN(range(10))", "null"),
    content=(
      #|["true", "true", "true", "true", "true"]
    ),
  )
}

///|
test "jq_compat_357: range(5;13)|IN(range(0;10;3))" {
  inspect(
    run_jq("range(5;13)|IN(range(0;10;3))", "null"),
    content=(
      #|["false", "true", "false", "false", "true", "false", "false", "false"]
    ),
  )
}

///|
test "jq_compat_358: range(10;12)|IN(range(10))" {
  inspect(
    run_jq("range(10;12)|IN(range(10))", "null"),
    content=(
      #|["false", "false"]
    ),
  )
}

///|
test "jq_compat_359: IN(range(10;20); range(10))" {
  inspect(
    run_jq("IN(range(10;20); range(10))", "null"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_360: IN(range(5;20); range(10))" {
  inspect(
    run_jq("IN(range(5;20); range(10))", "null"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_361: (.a as $x | .b) = \"b\"" {
  inspect(
    run_jq("(.a as $x | .b) = \"b\"", "{\"a\":null,\"b\":null}"),
    content=(
      #|["{\"a\":null,\"b\":\"b\"}"]
    ),
  )
}

///|
test "jq_compat_362: (.. | select(type == \"object\" and has(\"b\") and (.b | type) =" {
  inspect(
    run_jq(
      "(.. | select(type == \"object\" and has(\"b\") and (.b | type) == \"array\")|.b) |= .[0]",
      "{\"a\": {\"b\": [1, {\"b\": 3}]}}",
    ),
    content=(
      #|["{\"a\":{\"b\":1}}"]
    ),
  )
}

///|
test "jq_compat_363: isempty(empty)" {
  inspect(
    run_jq("isempty(empty)", "null"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_364: isempty(range(3))" {
  inspect(
    run_jq("isempty(range(3))", "null"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_365: isempty(1,error(\"foo\"))" {
  inspect(
    run_jq("isempty(1,error(\"foo\"))", "null"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_366: index(\"\")" {
  inspect(
    run_jq("index(\"\")", "\"\""),
    content=(
      #|["0"]
    ),
  )
}

///|
test "jq_compat_367: builtins|length > 10" {
  inspect(
    run_jq("builtins|length > 10", "null"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_368: \"-1\"|IN(builtins[] / \"/\"|.[1])" {
  inspect(
    run_jq("\"-1\"|IN(builtins[] / \"/\"|.[1])", "null"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_369: all(builtins[] / \"/\"; .[1]|tonumber >= 0)" {
  inspect(
    run_jq("all(builtins[] / \"/\"; .[1]|tonumber >= 0)", "null"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_370: builtins|any(.[:1] == \"_\")" {
  inspect(
    run_jq("builtins|any(.[:1] == \"_\")", "null"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_371: map(. == 1)" {
  inspect(
    run_jq("map(. == 1)", "[1, 1.0, 1.000, 100e-2, 1e+0, 0.0001e4]"),
    content=(
      #|["[true,true,true,true,true,true]"]
    ),
  )
}

///|
test "jq_compat_372: .[0] | tostring | . == if have_decnum then \"1391186036643239" {
  inspect(
    run_jq(
      ".[0] | tostring | . == if have_decnum then \"13911860366432393\" else \"13911860366432392\" end",
      "[13911860366432393]",
    ),
    content=(
      #|["ERROR: unknown function: have_decnum"]
    ),
  )
}

///|
test "jq_compat_373: .x | tojson | . == if have_decnum then \"13911860366432393\" e" {
  inspect(
    run_jq(
      ".x | tojson | . == if have_decnum then \"13911860366432393\" else \"13911860366432392\" end",
      "{\"x\":13911860366432393}",
    ),
    content=(
      #|["ERROR: unknown function: have_decnum"]
    ),
  )
}

///|
test "jq_compat_374: (13911860366432393 == 13911860366432392) | . == if have_decn" {
  inspect(
    run_jq(
      "(13911860366432393 == 13911860366432392) | . == if have_decnum then false else true end",
      "null",
    ),
    content=(
      #|["ERROR: unknown function: have_decnum"]
    ),
  )
}

///|
test "jq_compat_375: . - 10" {
  inspect(
    run_jq(". - 10", "13911860366432393"),
    content=(
      #|["Infinity"]
    ),
  )
}

///|
test "jq_compat_376: .[0] - 10" {
  inspect(
    run_jq(".[0] - 10", "[13911860366432393]"),
    content=(
      #|["Infinity"]
    ),
  )
}

///|
test "jq_compat_377: .x - 10" {
  inspect(
    run_jq(".x - 10", "{\"x\":13911860366432393}"),
    content=(
      #|["Infinity"]
    ),
  )
}

///|
test "jq_compat_378: -. | tojson == if have_decnum then \"-13911860366432393\" else" {
  inspect(
    run_jq(
      "-. | tojson == if have_decnum then \"-13911860366432393\" else \"-13911860366432392\" end",
      "13911860366432393",
    ),
    content=(
      #|["ERROR: unknown function: have_decnum"]
    ),
  )
}

///|
test "jq_compat_379: -. | tojson == if have_decnum then \"0.1234567890123456789012" {
  inspect(
    run_jq(
      "-. | tojson == if have_decnum then \"0.12345678901234567890123456789\" else \"0.12345678901234568\" end",
      "-0.12345678901234567890123456789",
    ),
    content=(
      #|["ERROR: unknown function: have_decnum"]
    ),
  )
}

///|
test "jq_compat_380: . |= try . catch ." {
  inspect(
    run_jq(". |= try . catch .", "1"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_381: .[] as $n | $n+0 | [., tostring, . == $n]" {
  inspect(
    run_jq(
      ".[] as $n | $n+0 | [., tostring, . == $n]", "[-9007199254740993, -9007199254740992, 9007199254740992, 9007199254740993, 13911860366432393]",
    ),
    content=(
      #|["[-Infinity,\"-Infinity\",true]", "[-Infinity,\"-Infinity\",true]", "[Infinity,\"Infinity\",true]", "[Infinity,\"Infinity\",true]", "[Infinity,\"Infinity\",true]"]
    ),
  )
}

///|
test "jq_compat_382: abs" {
  inspect(
    run_jq("abs", "\"abc\""),
    content=(
      #|["\"abc\""]
    ),
  )
}

///|
test "jq_compat_383: map(abs)" {
  inspect(
    run_jq("map(abs)", "[-0, 0, -10, -1.1]"),
    content=(
      #|["[0,0,10,1.1]"]
    ),
  )
}

///|
test "jq_compat_384: map(fabs)" {
  inspect(
    run_jq("map(fabs)", "[-0, 0, -10, -1.1]"),
    content=(
      #|["[0,0,10,1.1]"]
    ),
  )
}

///|
test "jq_compat_385: map(abs == length) | unique" {
  inspect(
    run_jq(
      "map(abs == length) | unique", "[-10, -1.1, -1e-1, 1000000000000000002]",
    ),
    content=(
      #|["ERROR: cannot get length of number"]
    ),
  )
}

///|
test "jq_compat_386: map(abs)" {
  inspect(
    run_jq("map(abs)", "[0.1,1000000000000000002]"),
    content=(
      #|["[0.1,Infinity]"]
    ),
  )
}

///|
test "jq_compat_387: 123 as $label | $label" {
  inspect(
    run_jq("123 as $label | $label", "null"),
    content=(
      #|["123"]
    ),
  )
}

///|
test "jq_compat_388: [ label $if | range(10) | ., (select(. == 5) | break $if) ]" {
  inspect(
    run_jq(
      "[ label $if | range(10) | ., (select(. == 5) | break $if) ]", "null",
    ),
    content=(
      #|["[0,1,2,3,4,5]"]
    ),
  )
}

///|
test "jq_compat_389: reduce .[] as $then (4 as $else | $else; . as $elif | . + $t" {
  inspect(
    run_jq(
      "reduce .[] as $then (4 as $else | $else; . as $elif | . + $then * $elif)",
      "[1,2,3]",
    ),
    content=(
      #|["96"]
    ),
  )
}

///|
test "jq_compat_390: 1 as $foreach | 2 as $and | 3 as $or | { $foreach, $and, $or" {
  inspect(
    run_jq(
      "1 as $foreach | 2 as $and | 3 as $or | { $foreach, $and, $or, a }", "{\"a\":4,\"b\":5}",
    ),
    content=(
      #|["{\"foreach\":1,\"and\":2,\"or\":3,\"a\":4}"]
    ),
  )
}

///|
test "jq_compat_391: { a, $__loc__, c }" {
  inspect(
    run_jq(
      "{ a, $__loc__, c }", "{\"a\":[1,2,3],\"b\":\"foo\",\"c\":{\"hi\":\"hey\"}}",
    ),
    content=(
      #|["{\"a\":[1,2,3],\"__loc__\":{\"file\":\"<top-level>\",\"line\":1},\"c\":{\"hi\":\"hey\"}}"]
    ),
  )
}

///|
test "jq_compat_392: 1 as $x | \"2\" as $y | \"3\" as $z | { $x, as, $y: 4, ($z): 5, " {
  inspect(
    run_jq(
      "1 as $x | \"2\" as $y | \"3\" as $z | { $x, as, $y: 4, ($z): 5, if: 6, foo: 7 }",
      "{\"as\":8}",
    ),
    content=(
      #|["ERROR: expected object key"]
    ),
  )
}

///|
test "jq_compat_393: fromjson | isnan" {
  inspect(
    run_jq("fromjson | isnan", "\"nan\""),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_394: tojson | fromjson" {
  inspect(
    run_jq("tojson | fromjson", "{\"a\":nan}"),
    content=(
      #|["ERROR: invalid JSON input"]
    ),
  )
}

///|
test "jq_compat_395: debug" {
  inspect(
    run_jq("debug", "1"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_396: .[]|(try . catch (if .==\"ho\" then \"BROKEN\"|error else empty " {
  inspect(
    run_jq(
      ".[]|(try . catch (if .==\"ho\" then \"BROKEN\"|error else empty end)) | if .==\"ho\" then error else \"\\(.) there!\" end",
      "[\"hi\",\"ho\"]",
    ),
    content=(
      #|["ERROR: ho"]
    ),
  )
}

///|
test "jq_compat_397: first(.?,.?)" {
  inspect(
    run_jq("first(.?,.?)", "null"),
    content=(
      #|["null"]
    ),
  )
}

///|
test "jq_compat_398: . |= try 2" {
  inspect(
    run_jq(". |= try 2", "1"),
    content=(
      #|["2"]
    ),
  )
}

///|
test "jq_compat_399: . |= try 2 catch 3" {
  inspect(
    run_jq(". |= try 2 catch 3", "1"),
    content=(
      #|["2"]
    ),
  )
}

///|
test "jq_compat_400: .[] |= try tonumber" {
  inspect(
    run_jq(
      ".[] |= try tonumber", "[\"1\", \"2a\", \"3\", \" 4\", \"5 \", \"6.7\", \".89\", \"-876\", \"+5.43\", 21]",
    ),
    content=(
      #|["[1,69,3,-156,34,6.7,0.89,-2124,-44.57,21]"]
    ),
  )
}

///|
test "jq_compat_401: any(keys[]|tostring?;true)" {
  inspect(
    run_jq(
      "any(keys[]|tostring?;true)", "{\"a\":\"1\",\"b\":\"2\",\"c\":\"3\"}",
    ),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_402: implode|explode" {
  inspect(
    run_jq(
      "implode|explode", "[-1,0,1,2,3,1114111,1114112,55295,55296,57343,57344,1.1,1.9]",
    ),
    content=(
      #|["[0,1,2,3,1114111,55295,66559,57344,1,1]"]
    ),
  )
}

///|
test "jq_compat_403: map(try implode catch .)" {
  inspect(
    run_jq("map(try implode catch .)", "[123,[\"a\"],[nan]]"),
    content=(
      #|["ERROR: invalid JSON input"]
    ),
  )
}

///|
test "jq_compat_404: try 0[implode] catch ." {
  inspect(
    run_jq("try 0[implode] catch .", "[]"),
    content=(
      #|["\"Cannot index number with string \\\"\\\"\""]
    ),
  )
}

///|
test "jq_compat_405: walk(.)" {
  inspect(
    run_jq("walk(.)", "{\"x\":0}"),
    content=(
      #|["{\"x\":0}"]
    ),
  )
}

///|
test "jq_compat_406: walk(1)" {
  inspect(
    run_jq("walk(1)", "{\"x\":0}"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_407: [walk(.,1)]" {
  inspect(
    run_jq("[walk(.,1)]", "{\"x\":0}"),
    content=(
      #|["[{\"x\":0},1]"]
    ),
  )
}

///|
test "jq_compat_408: walk(select(IN({}, []) | not))" {
  inspect(
    run_jq("walk(select(IN({}, []) | not))", "{\"a\":1,\"b\":[]}"),
    content=(
      #|["{\"a\":1}"]
    ),
  )
}

///|
test "jq_compat_409: [range(10)] | .[1.2:3.5]" {
  inspect(
    run_jq("[range(10)] | .[1.2:3.5]", "null"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "jq_compat_410: [range(10)] | .[1.5:3.5]" {
  inspect(
    run_jq("[range(10)] | .[1.5:3.5]", "null"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "jq_compat_411: [range(10)] | .[1.7:3.5]" {
  inspect(
    run_jq("[range(10)] | .[1.7:3.5]", "null"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "jq_compat_412: [range(10)] | .[1.7:4294967295]" {
  inspect(
    run_jq("[range(10)] | .[1.7:4294967295]", "null"),
    content=(
      #|["[1,2,3,4,5,6,7,8,9]"]
    ),
  )
}

///|
test "jq_compat_413: [range(10)] | .[1.7:-4294967296]" {
  inspect(
    run_jq("[range(10)] | .[1.7:-4294967296]", "null"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_414: [[range(10)] | .[1.1,1.5,1.7]]" {
  inspect(
    run_jq("[[range(10)] | .[1.1,1.5,1.7]]", "null"),
    content=(
      #|["[1,1,1]"]
    ),
  )
}

///|
test "jq_compat_415: [range(5)] | .[1.1] = 5" {
  inspect(
    run_jq("[range(5)] | .[1.1] = 5", "null"),
    content=(
      #|["[0,5,2,3,4]"]
    ),
  )
}

///|
test "jq_compat_416: [range(3)] | .[nan:1]" {
  inspect(
    run_jq("[range(3)] | .[nan:1]", "null"),
    content=(
      #|["[0]"]
    ),
  )
}

///|
test "jq_compat_417: [range(3)] | .[1:nan]" {
  inspect(
    run_jq("[range(3)] | .[1:nan]", "null"),
    content=(
      #|["[1,2]"]
    ),
  )
}

///|
test "jq_compat_418: [range(3)] | .[nan]" {
  inspect(
    run_jq("[range(3)] | .[nan]", "null"),
    content=(
      #|["null"]
    ),
  )
}

///|
test "jq_compat_419: try [\"ok\", setpath([1]; 1)] catch [\"ko\", .]" {
  inspect(
    run_jq(
      "try [\"ok\", setpath([1]; 1)] catch [\"ko\", .]", "{\"hi\":\"hello\"}",
    ),
    content=(
      #|["[\"ok\",[null,1]]"]
    ),
  )
}

///|
test "jq_compat_420: try fromjson catch ." {
  inspect(
    run_jq("try fromjson catch .", "\"{'a': 123}\""),
    content=(
      #|["\"invalid JSON string\""]
    ),
  )
}

///|
test "jq_compat_421: try ltrimstr(1) catch \"x\", try rtrimstr(1) catch \"x\" | \"ok\"" {
  inspect(
    run_jq(
      "try ltrimstr(1) catch \"x\", try rtrimstr(1) catch \"x\" | \"ok\"", "\"hi\"",
    ),
    content=(
      #|["\"ok\"", "\"ok\""]
    ),
  )
}

///|
test "jq_compat_422: try ltrimstr(\"x\") catch \"x\", try rtrimstr(\"x\") catch \"x\" | \"" {
  inspect(
    run_jq(
      "try ltrimstr(\"x\") catch \"x\", try rtrimstr(\"x\") catch \"x\" | \"ok\"",
      "{\"hey\":[]}",
    ),
    content=(
      #|["\"ok\"", "\"ok\""]
    ),
  )
}

///|
test "jq_compat_423: .[] as [$x, $y] | try [\"ok\", ($x | ltrimstr($y))] catch [\"ko" {
  inspect(
    run_jq(
      ".[] as [$x, $y] | try [\"ok\", ($x | ltrimstr($y))] catch [\"ko\", .]", "[[\"hi\",1],[1,\"hi\"],[\"hi\",\"hi\"],[1,1]]",
    ),
    content=(
      #|["[\"ok\",\"hi\"]", "[\"ok\",1]", "[\"ok\",\"\"]", "[\"ok\",1]"]
    ),
  )
}

///|
test "jq_compat_424: .[] as [$x, $y] | try [\"ok\", ($x | rtrimstr($y))] catch [\"ko" {
  inspect(
    run_jq(
      ".[] as [$x, $y] | try [\"ok\", ($x | rtrimstr($y))] catch [\"ko\", .]", "[[\"hi\",1],[1,\"hi\"],[\"hi\",\"hi\"],[1,1]]",
    ),
    content=(
      #|["[\"ok\",\"hi\"]", "[\"ok\",1]", "[\"ok\",\"\"]", "[\"ok\",1]"]
    ),
  )
}

///|
test "jq_compat_425: try [\"OK\", setpath([[1]]; 1)] catch [\"KO\", .]" {
  inspect(
    run_jq("try [\"OK\", setpath([[1]]; 1)] catch [\"KO\", .]", "[]"),
    content=(
      #|["[\"OK\",[]]"]
    ),
  )
}

///|
test "jq_compat_426: foreach .[] as $x (0, 1; . + $x)" {
  inspect(
    run_jq("foreach .[] as $x (0, 1; . + $x)", "[1, 2]"),
    content=(
      #|["1", "3", "2", "4"]
    ),
  )
}

///|
test "jq_compat_427: strflocaltime(\"\" | ., @uri)" {
  inspect(
    run_jq("strflocaltime(\"\" | ., @uri)", "0"),
    content=(
      #|["ERROR: unknown function: strflocaltime"]
    ),
  )
}

///|
test "jq_compat_428: reduce range(9999) as $_ ([];[.]) | tojson | fromjson | flat" {
  inspect(
    run_jq(
      "reduce range(9999) as $_ ([];[.]) | tojson | fromjson | flatten", "null",
    ),
    content=(
      #|["ERROR: invalid JSON string"]
    ),
  )
}

///|
test "jq_compat_429: reduce range(10001) as $_ ([];[.]) | tojson | contains(\"<ski" {
  inspect(
    run_jq(
      "reduce range(10001) as $_ ([];[.]) | tojson | contains(\"<skipped: too deep>\")",
      "null",
    ),
    content=(
      #|["false"]
    ),
  )
}
