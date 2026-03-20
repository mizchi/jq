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
test "jq_compat_11: @base64" {
  inspect(
    run_jq("@base64", "\"foóbar\\n\""),
    content=(
      #|["\"Zm/Ds2Jhcgo=\""]
    ),
  )
}

///|
test "jq_compat_12: @base64d" {
  inspect(
    run_jq("@base64d", "\"Zm/Ds2Jhcgo=\""),
    content=(
      #|["\"foóbar\\n\""]
    ),
  )
}

///|
test "jq_compat_13: @uri" {
  inspect(
    run_jq("@uri", "\"\\u03bc\""),
    content=(
      #|["\"%CE%BC\""]
    ),
  )
}

///|
test "jq_compat_14: [.[]|tojson|fromjson]" {
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
test "jq_compat_15: {a: 1}" {
  inspect(
    run_jq("{a: 1}", "null"),
    content=(
      #|["{\"a\":1}"]
    ),
  )
}

///|
test "jq_compat_16: {a,b,(.d):.a,e:.b}" {
  inspect(
    run_jq("{a,b,(.d):.a,e:.b}", "{\"a\":1, \"b\":2, \"c\":3, \"d\":\"c\"}"),
    content=(
      #|["{\"a\":1,\"b\":2,\"c\":1,\"e\":2}"]
    ),
  )
}

///|
test "jq_compat_17: .foo" {
  inspect(
    run_jq(".foo", "{\"foo\": 42, \"bar\": 43}"),
    content=(
      #|["42"]
    ),
  )
}

///|
test "jq_compat_18: .foo | .bar" {
  inspect(
    run_jq(".foo | .bar", "{\"foo\": {\"bar\": 42}, \"bar\": \"badvalue\"}"),
    content=(
      #|["42"]
    ),
  )
}

///|
test "jq_compat_19: .foo.bar" {
  inspect(
    run_jq(".foo.bar", "{\"foo\": {\"bar\": 42}, \"bar\": \"badvalue\"}"),
    content=(
      #|["42"]
    ),
  )
}

///|
test "jq_compat_20: .foo_bar" {
  inspect(
    run_jq(".foo_bar", "{\"foo_bar\": 2}"),
    content=(
      #|["2"]
    ),
  )
}

///|
test "jq_compat_21: .[\"foo\"].bar" {
  inspect(
    run_jq(".[\"foo\"].bar", "{\"foo\": {\"bar\": 42}, \"bar\": \"badvalue\"}"),
    content=(
      #|["42"]
    ),
  )
}

///|
test "jq_compat_22: .\"foo\".\"bar\"" {
  inspect(
    run_jq(".\"foo\".\"bar\"", "{\"foo\": {\"bar\": 20}}"),
    content=(
      #|["20"]
    ),
  )
}

///|
test "jq_compat_23: [.[]|.foo?]" {
  inspect(
    run_jq("[.[]|.foo?]", "[1,[2],{\"foo\":3,\"bar\":4},{},{\"foo\":5}]"),
    content=(
      #|["[3,null,5]"]
    ),
  )
}

///|
test "jq_compat_24: [.[]|.foo?.bar?]" {
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
test "jq_compat_25: [..]" {
  inspect(
    run_jq("[..]", "[1,[[2]],{ \"a\":[1]}]"),
    content=(
      #|["[[1,[[2]],{\"a\":[1]}],1,[[2]],[2],2,{\"a\":[1]},[1],1]"]
    ),
  )
}

///|
test "jq_compat_26: [.[]|.[1:3]?]" {
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
test "jq_compat_27: try [\"OK\", (.[] | error)] catch [\"KO\", .]" {
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
test "jq_compat_28: .[]" {
  inspect(
    run_jq(".[]", "[1,2,3]"),
    content=(
      #|["1", "2", "3"]
    ),
  )
}

///|
test "jq_compat_29: 1,1" {
  inspect(
    run_jq("1,1", "[]"),
    content=(
      #|["1", "1"]
    ),
  )
}

///|
test "jq_compat_30: 1,." {
  inspect(
    run_jq("1,.", "[]"),
    content=(
      #|["1", "[]"]
    ),
  )
}

///|
test "jq_compat_31: [.]" {
  inspect(
    run_jq("[.]", "[2]"),
    content=(
      #|["[[2]]"]
    ),
  )
}

///|
test "jq_compat_32: [[2]]" {
  inspect(
    run_jq("[[2]]", "[3]"),
    content=(
      #|["[[2]]"]
    ),
  )
}

///|
test "jq_compat_33: [{}]" {
  inspect(
    run_jq("[{}]", "[2]"),
    content=(
      #|["[{}]"]
    ),
  )
}

///|
test "jq_compat_34: [.[]]" {
  inspect(
    run_jq("[.[]]", "[\"a\"]"),
    content=(
      #|["[\"a\"]"]
    ),
  )
}

///|
test "jq_compat_35: [(.,1),((.,.[]),(2,3))]" {
  inspect(
    run_jq("[(.,1),((.,.[]),(2,3))]", "[\"a\",\"b\"]"),
    content=(
      #|["[[\"a\",\"b\"],1,[\"a\",\"b\"],\"a\",\"b\",2,3]"]
    ),
  )
}

///|
test "jq_compat_36: [([5,5][]),.,.[]]" {
  inspect(
    run_jq("[([5,5][]),.,.[]]", "[1,2,3]"),
    content=(
      #|["[5,5,[1,2,3],1,2,3]"]
    ),
  )
}

///|
test "jq_compat_37: {x: (1,2)},{x:3} | .x" {
  inspect(
    run_jq("{x: (1,2)},{x:3} | .x", "null"),
    content=(
      #|["1", "2", "3"]
    ),
  )
}

///|
test "jq_compat_38: [.[-4,-3,-2,-1,0,1,2,3]]" {
  inspect(
    run_jq("[.[-4,-3,-2,-1,0,1,2,3]]", "[1,2,3]"),
    content=(
      #|["[null,1,2,3,1,2,3,null]"]
    ),
  )
}

///|
test "jq_compat_39: [range(0;10)]" {
  inspect(
    run_jq("[range(0;10)]", "null"),
    content=(
      #|["[0,1,2,3,4,5,6,7,8,9]"]
    ),
  )
}

///|
test "jq_compat_40: [range(0,1;3,4)]" {
  inspect(
    run_jq("[range(0,1;3,4)]", "null"),
    content=(
      #|["[0,1,2,0,1,2,3,1,2,1,2,3]"]
    ),
  )
}

///|
test "jq_compat_41: [range(0;10;3)]" {
  inspect(
    run_jq("[range(0;10;3)]", "null"),
    content=(
      #|["[0,3,6,9]"]
    ),
  )
}

///|
test "jq_compat_42: [range(0;10;-1)]" {
  inspect(
    run_jq("[range(0;10;-1)]", "null"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_43: [range(0;-5;-1)]" {
  inspect(
    run_jq("[range(0;-5;-1)]", "null"),
    content=(
      #|["[0,-1,-2,-3,-4]"]
    ),
  )
}

///|
test "jq_compat_44: [range(0,1;4,5;1,2)]" {
  inspect(
    run_jq("[range(0,1;4,5;1,2)]", "null"),
    content=(
      #|["[0,1,2,3,0,2,0,1,2,3,4,0,2,4,1,2,3,1,3,1,2,3,4,1,3]"]
    ),
  )
}

///|
test "jq_compat_45: [while(.<100; .*2)]" {
  inspect(
    run_jq("[while(.<100; .*2)]", "1"),
    content=(
      #|["[1,2,4,8,16,32,64]"]
    ),
  )
}

///|
test "jq_compat_46: [.[]|[.,1]|until(.[0] < 1; [.[0] - 1, .[1] * .[0]])|.[1]]" {
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
test "jq_compat_47: [foreach range(5) as $item (0; $item)]" {
  inspect(
    run_jq("[foreach range(5) as $item (0; $item)]", "null"),
    content=(
      #|["[0,1,2,3,4]"]
    ),
  )
}

///|
test "jq_compat_48: [-foreach -.[] as $x (0; . + $x)]" {
  inspect(
    run_jq("[-foreach -.[] as $x (0; . + $x)]", "[1,2,3]"),
    content=(
      #|["[1,3,6]"]
    ),
  )
}

///|
test "jq_compat_49: [foreach .[] / .[] as $i (0; . + $i)]" {
  inspect(
    run_jq("[foreach .[] / .[] as $i (0; . + $i)]", "[1,2]"),
    content=(
      #|["ERROR: expected KwAs but got Slash"]
    ),
  )
}

///|
test "jq_compat_50: [foreach .[] as $x (0; . + $x) as $x | $x]" {
  inspect(
    run_jq("[foreach .[] as $x (0; . + $x) as $x | $x]", "[1,2,3]"),
    content=(
      #|["[1,3,6]"]
    ),
  )
}

///|
test "jq_compat_51: [limit(3; .[])]" {
  inspect(
    run_jq("[limit(3; .[])]", "[11,22,33,44,55,66,77,88,99]"),
    content=(
      #|["[11,22,33]"]
    ),
  )
}

///|
test "jq_compat_52: [limit(0; error)]" {
  inspect(
    run_jq("[limit(0; error)]", "\"badness\""),
    content=(
      #|["ERROR: badness"]
    ),
  )
}

///|
test "jq_compat_53: [limit(1; 1, error)]" {
  inspect(
    run_jq("[limit(1; 1, error)]", "\"badness\""),
    content=(
      #|["[1]"]
    ),
  )
}

///|
test "jq_compat_54: try limit(-1; error) catch ." {
  inspect(
    run_jq("try limit(-1; error) catch .", "null"),
    content=(
      #|["\"limit doesn't support negative count\""]

    ),
  )
}

///|
test "jq_compat_55: [skip(3; .[])]" {
  inspect(
    run_jq("[skip(3; .[])]", "[1,2,3,4,5,6,7,8,9]"),
    content=(
      #|["[4,5,6,7,8,9]"]
    ),
  )
}

///|
test "jq_compat_56: [skip(0,2,3,4; .[])]" {
  inspect(
    run_jq("[skip(0,2,3,4; .[])]", "[1,2,3]"),
    content=(
      #|["[1,2,3,3]"]
    ),
  )
}

///|
test "jq_compat_57: [skip(3; .[])]" {
  inspect(
    run_jq("[skip(3; .[])]", "[]"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_58: try skip(-1; error) catch ." {
  inspect(
    run_jq("try skip(-1; error) catch .", "null"),
    content=(
      #|["\"skip doesn't support negative count\""]
    ),
  )
}

///|
test "jq_compat_59: nth(1; 0,1,error(\"foo\"))" {
  inspect(
    run_jq("nth(1; 0,1,error(\"foo\"))", "null"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_60: [first(range(.)), last(range(.))]" {
  inspect(
    run_jq("[first(range(.)), last(range(.))]", "10"),
    content=(
      #|["[0,9]"]
    ),
  )
}

///|
test "jq_compat_61: [first(range(.)), last(range(.))]" {
  inspect(
    run_jq("[first(range(.)), last(range(.))]", "0"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_62: [nth(0,5,9,10,15; range(.)), try nth(-1; range(.)) catch .]" {
  inspect(
    run_jq("[nth(0,5,9,10,15; range(.)), try nth(-1; range(.)) catch .]", "10"),
    content=(
      #|["[0,5,9,\"nth doesn't support negative indices\"]"]
    ),
  )
}

///|
test "jq_compat_63: first(1,error(\"foo\"))" {
  inspect(
    run_jq("first(1,error(\"foo\"))", "null"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_64: [limit(5,7; range(9))]" {
  inspect(
    run_jq("[limit(5,7; range(9))]", "null"),
    content=(
      #|["[0,1,2,3,4,0,1,2,3,4,5,6]"]
    ),
  )
}

///|
test "jq_compat_65: [nth(5,7; range(9;0;-1))]" {
  inspect(
    run_jq("[nth(5,7; range(9;0;-1))]", "null"),
    content=(
      #|["[4,2]"]
    ),
  )
}

///|
test "jq_compat_66: [range(0,1,2;4,3,2;2,3)]" {
  inspect(
    run_jq("[range(0,1,2;4,3,2;2,3)]", "null"),
    content=(
      #|["[0,2,0,3,0,2,0,0,0,1,3,1,1,1,1,1,2,2,2,2]"]
    ),
  )
}

///|
test "jq_compat_67: [range(3,5)]" {
  inspect(
    run_jq("[range(3,5)]", "null"),
    content=(
      #|["[0,1,2,0,1,2,3,4]"]
    ),
  )
}

///|
test "jq_compat_68: [(index(\",\",\"|\"), rindex(\",\",\"|\")), indices(\",\",\"|\")]" {
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
test "jq_compat_69: join(\",\",\"/\")" {
  inspect(
    run_jq("join(\",\",\"/\")", "[\"a\",\"b\",\"c\",\"d\"]"),
    content=(
      #|["\"a,b,c,d\"", "\"a/b/c/d\""]
    ),
  )
}

///|
test "jq_compat_70: [.[]|join(\"a\")]" {
  inspect(
    run_jq("[.[]|join(\"a\")]", "[[],[\"\"],[\"\",\"\"],[\"\",\"\",\"\"]]"),
    content=(
      #|["[\"\",\"\",\"a\",\"aa\"]"]
    ),
  )
}

///|
test "jq_compat_71: [.[3:2], .[-5:4], .[:-2], .[-2:], .[3:3][1:], .[10:]]" {
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
test "jq_compat_72: [.[3:2], .[-5:4], .[:-2], .[-2:], .[3:3][1:], .[10:]]" {
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
test "jq_compat_73: 1 as $x | 2 as $y | [$x,$y,$x]" {
  inspect(
    run_jq("1 as $x | 2 as $y | [$x,$y,$x]", "null"),
    content=(
      #|["[1,2,1]"]
    ),
  )
}

///|
test "jq_compat_74: [1,2,3][] as $x | [[4,5,6,7][$x]]" {
  inspect(
    run_jq("[1,2,3][] as $x | [[4,5,6,7][$x]]", "null"),
    content=(
      #|["[5]", "[6]", "[7]"]
    ),
  )
}

///|
test "jq_compat_75: 42 as $x | . | . | . + 432 | $x + 1" {
  inspect(
    run_jq("42 as $x | . | . | . + 432 | $x + 1", "34324"),
    content=(
      #|["43"]
    ),
  )
}

///|
test "jq_compat_76: \"x\" as $x | \"a\"+\"y\" as $y | $x+\",\"+$y" {
  inspect(
    run_jq("\"x\" as $x | \"a\"+\"y\" as $y | $x+\",\"+$y", "null"),
    content=(
      #|["\"x,ay\""]
    ),
  )
}

///|
test "jq_compat_77: 1 as $x | [$x,$x,$x as $x | $x]" {
  inspect(
    run_jq("1 as $x | [$x,$x,$x as $x | $x]", "null"),
    content=(
      #|["[1,1,1]"]
    ),
  )
}

///|
test "jq_compat_78: 1+1" {
  inspect(
    run_jq("1+1", "null"),
    content=(
      #|["2"]
    ),
  )
}

///|
test "jq_compat_79: 1+1" {
  inspect(
    run_jq("1+1", "\"wtasdf\""),
    content=(
      #|["2"]
    ),
  )
}

///|
test "jq_compat_80: 2-1" {
  inspect(
    run_jq("2-1", "null"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_81: 2-(-1)" {
  inspect(
    run_jq("2-(-1)", "null"),
    content=(
      #|["3"]
    ),
  )
}

///|
test "jq_compat_82: .+4" {
  inspect(
    run_jq(".+4", "15"),
    content=(
      #|["19"]
    ),
  )
}

///|
test "jq_compat_83: .+null" {
  inspect(
    run_jq(".+null", "{\"a\":42}"),
    content=(
      #|["{\"a\":42}"]
    ),
  )
}

///|
test "jq_compat_84: null+." {
  inspect(
    run_jq("null+.", "null"),
    content=(
      #|["null"]
    ),
  )
}

///|
test "jq_compat_85: .a+.b" {
  inspect(
    run_jq(".a+.b", "{\"a\":42}"),
    content=(
      #|["42"]
    ),
  )
}

///|
test "jq_compat_86: [1,2,3] + [.]" {
  inspect(
    run_jq("[1,2,3] + [.]", "null"),
    content=(
      #|["[1,2,3,null]"]
    ),
  )
}

///|
test "jq_compat_87: {\"a\":1} + {\"b\":2} + {\"c\":3}" {
  inspect(
    run_jq("{\"a\":1} + {\"b\":2} + {\"c\":3}", "\"asdfasdf\""),
    content=(
      #|["{\"a\":1,\"b\":2,\"c\":3}"]
    ),
  )
}

///|
test "jq_compat_88: \"asdf\" + \"jkl;\" + . + . + ." {
  inspect(
    run_jq("\"asdf\" + \"jkl;\" + . + . + .", "\"some string\""),
    content=(
      #|["\"asdfjkl;some stringsome stringsome string\""]
    ),
  )
}

///|
test "jq_compat_89: \"\\u0000\\u0020\\u0000\" + ." {
  inspect(
    run_jq("\"\\u0000\\u0020\\u0000\" + .", "\"\\u0000\\u0020\\u0000\""),
    content=(
      #|["\"\\\\u0000\\\\u0020\\\\u0000\\u0000 \\u0000\""]
    ),
  )
}

///|
test "jq_compat_90: 42 - ." {
  inspect(
    run_jq("42 - .", "11"),
    content=(
      #|["31"]
    ),
  )
}

///|
test "jq_compat_91: [-1 as $x | 1,$x]" {
  inspect(
    run_jq("[-1 as $x | 1,$x]", "null"),
    content=(
      #|["[1,-1]"]
    ),
  )
}

///|
test "jq_compat_92: [10 * 20, 20 / .]" {
  inspect(
    run_jq("[10 * 20, 20 / .]", "4"),
    content=(
      #|["[200,5]"]
    ),
  )
}

///|
test "jq_compat_93: 1 + 2 * 2 + 10 / 2" {
  inspect(
    run_jq("1 + 2 * 2 + 10 / 2", "null"),
    content=(
      #|["10"]
    ),
  )
}

///|
test "jq_compat_94: [16 / 4 / 2, 16 / 4 * 2, 16 - 4 - 2, 16 - 4 + 2]" {
  inspect(
    run_jq("[16 / 4 / 2, 16 / 4 * 2, 16 - 4 - 2, 16 - 4 + 2]", "null"),
    content=(
      #|["[2,8,10,14]"]
    ),
  )
}

///|
test "jq_compat_95: 25 % 7" {
  inspect(
    run_jq("25 % 7", "null"),
    content=(
      #|["4"]
    ),
  )
}

///|
test "jq_compat_96: 49732 % 472" {
  inspect(
    run_jq("49732 % 472", "null"),
    content=(
      #|["172"]
    ),
  )
}

///|
test "jq_compat_97: 1 + tonumber + (\"10\" | tonumber)" {
  inspect(
    run_jq("1 + tonumber + (\"10\" | tonumber)", "4"),
    content=(
      #|["15"]
    ),
  )
}

///|
test "jq_compat_98: \"123\\u0000456\" | try tonumber catch ." {
  inspect(
    run_jq("\"123\\u0000456\" | try tonumber catch .", "null"),
    content=(
      #|["128090000456"]
    ),
  )
}

///|
test "jq_compat_99: map(toboolean)" {
  inspect(
    run_jq("map(toboolean)", "[\"false\",\"true\",false,true]"),
    content=(
      #|["[false,true,false,true]"]
    ),
  )
}

///|
test "jq_compat_100: .[] | try toboolean catch ." {
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
test "jq_compat_101: \"true\\u0000x\", \"false\\u0000\" | try toboolean catch ." {
  inspect(
    run_jq("\"true\\u0000x\", \"false\\u0000\" | try toboolean catch .", "null"),
    content=(
      #|["\"string (\\\"true\\\\\\\\u0000x\\\") cannot be parsed as a boolean\"", "\"string (\\\"false\\\\\\\\u0000\\\") cannot be parsed as a boolean\""]
    ),
  )
}

///|
test "jq_compat_102: [{\"a\":42},.object,10,.num,false,true,null,\"b\",[1,4]] | .[] a" {
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
test "jq_compat_103: [.[] | length]" {
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
test "jq_compat_104: map(keys)" {
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
test "jq_compat_105: [1,2,empty,3,empty,4]" {
  inspect(
    run_jq("[1,2,empty,3,empty,4]", "null"),
    content=(
      #|["[1,2,3,4]"]
    ),
  )
}

///|
test "jq_compat_106: map(add)" {
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
test "jq_compat_107: map_values(.+1)" {
  inspect(
    run_jq("map_values(.+1)", "[0,1,2]"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "jq_compat_108: def f: (1000,2000); f" {
  inspect(
    run_jq("def f: (1000,2000); f", "123412345"),
    content=(
      #|["1000", "2000"]
    ),
  )
}

///|
test "jq_compat_109: def f(a;b;c;d;e;f): [a+1,b,c,d,e,f]; f(.[0];.[1];.[0];.[0];." {
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
test "jq_compat_110: def a: 0; . | a" {
  inspect(
    run_jq("def a: 0; . | a", "null"),
    content=(
      #|["0"]
    ),
  )
}

///|
test "jq_compat_111: def f(a;b;c;d;e;f;g;h;i;j): [j,i,h,g,f,e,d,c,b,a]; f(.[0];.[" {
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
test "jq_compat_112: ([1,2] + [4,5])" {
  inspect(
    run_jq("([1,2] + [4,5])", "[1,2,3]"),
    content=(
      #|["[1,2,4,5]"]
    ),
  )
}

///|
test "jq_compat_113: true" {
  inspect(
    run_jq("true", "[1]"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_114: null,1,null" {
  inspect(
    run_jq("null,1,null", "\"hello\""),
    content=(
      #|["null", "1", "null"]
    ),
  )
}

///|
test "jq_compat_115: [1,2,3]" {
  inspect(
    run_jq("[1,2,3]", "[5,6]"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "jq_compat_116: [.[]|floor]" {
  inspect(
    run_jq("[.[]|floor]", "[-1.1,1.1,1.9]"),
    content=(
      #|["[-2,1,1]"]
    ),
  )
}

///|
test "jq_compat_117: def f(x): x | x; f([.], . + [42])" {
  inspect(
    run_jq("def f(x): x | x; f([.], . + [42])", "[1,2,3]"),
    content=(
      #|["[[[1,2,3]]]", "[[1,2,3],42]", "[[1,2,3,42]]", "[1,2,3,42,42]"]
    ),
  )
}

///|
test "jq_compat_118: [[20,10][1,0] as $x | def f: (100,200) as $y | def g: [$x + " {
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
test "jq_compat_119: def fac: if . == 1 then 1 else . * (. - 1 | fac) end; [.[] |" {
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
test "jq_compat_120: reduce .[] as $x (0; . + $x)" {
  inspect(
    run_jq("reduce .[] as $x (0; . + $x)", "[1,2,4]"),
    content=(
      #|["7"]
    ),
  )
}

///|
test "jq_compat_121: [-reduce -.[] as $x (0; . + $x)]" {
  inspect(
    run_jq("[-reduce -.[] as $x (0; . + $x)]", "[1,2,3]"),
    content=(
      #|["[6]"]
    ),
  )
}

///|
test "jq_compat_122: [reduce .[] / .[] as $i (0; . + $i)]" {
  inspect(
    run_jq("[reduce .[] / .[] as $i (0; . + $i)]", "[1,2]"),
    content=(
      #|["[4.5]"]
    ),
  )
}

///|
test "jq_compat_123: reduce .[] as $x (0; . + $x) as $x | $x" {
  inspect(
    run_jq("reduce .[] as $x (0; . + $x) as $x | $x", "[1,2,3]"),
    content=(
      #|["6"]
    ),
  )
}

///|
test "jq_compat_124: reduce . as $n (.; .)" {
  inspect(
    run_jq("reduce . as $n (.; .)", "null"),
    content=(
      #|["null"]
    ),
  )
}

///|
test "jq_compat_125: . as $dot|any($dot[];not)" {
  inspect(
    run_jq(". as $dot|any($dot[];not)", "[1,2,3,4,true,false,1,2,3,4,5]"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_126: . as $dot|any($dot[];not)" {
  inspect(
    run_jq(". as $dot|any($dot[];not)", "[1,2,3,4,true]"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_127: . as $dot|all($dot[];.)" {
  inspect(
    run_jq(". as $dot|all($dot[];.)", "[1,2,3,4,true,false,1,2,3,4,5]"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_128: . as $dot|all($dot[];.)" {
  inspect(
    run_jq(". as $dot|all($dot[];.)", "[1,2,3,4,true]"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_129: any(true, error; .)" {
  inspect(
    run_jq("any(true, error; .)", "\"badness\""),
    content=(
      #|["ERROR: badness"]
    ),
  )
}

///|
test "jq_compat_130: all(false, error; .)" {
  inspect(
    run_jq("all(false, error; .)", "\"badness\""),
    content=(
      #|["ERROR: badness"]
    ),
  )
}

///|
test "jq_compat_131: any(not)" {
  inspect(
    run_jq("any(not)", "[]"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_132: all(not)" {
  inspect(
    run_jq("all(not)", "[]"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_133: any(not)" {
  inspect(
    run_jq("any(not)", "[false]"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_134: all(not)" {
  inspect(
    run_jq("all(not)", "[false]"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_135: [any,all]" {
  inspect(
    run_jq("[any,all]", "[]"),
    content=(
      #|["[false,true]"]
    ),
  )
}

///|
test "jq_compat_136: [any,all]" {
  inspect(
    run_jq("[any,all]", "[true]"),
    content=(
      #|["[true,true]"]
    ),
  )
}

///|
test "jq_compat_137: [any,all]" {
  inspect(
    run_jq("[any,all]", "[false]"),
    content=(
      #|["[false,false]"]
    ),
  )
}

///|
test "jq_compat_138: [any,all]" {
  inspect(
    run_jq("[any,all]", "[true,false]"),
    content=(
      #|["[true,false]"]
    ),
  )
}

///|
test "jq_compat_139: [any,all]" {
  inspect(
    run_jq("[any,all]", "[null,null,true]"),
    content=(
      #|["[true,false]"]
    ),
  )
}

///|
test "jq_compat_140: [paths]" {
  inspect(
    run_jq("[paths]", "[1,[[],{\"a\":2}]]"),
    content=(
      #|["[[0],[1],[1,0],[1,1],[1,1,\"a\"]]"]
    ),
  )
}

///|
test "jq_compat_141: [.[] % 7]" {
  inspect(
    run_jq("[.[] % 7]", "[-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7]"),
    content=(
      #|["[0,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,0]"]
    ),
  )
}

///|
test "jq_compat_142: [.[] | if .foo then \"yep\" else \"nope\" end]" {
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
test "jq_compat_143: [.[] | if .baz then \"strange\" elif .foo then \"yep\" else \"nop" {
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
test "jq_compat_144: [if 1,null,2 then 3 else 4 end]" {
  inspect(
    run_jq("[if 1,null,2 then 3 else 4 end]", "null"),
    content=(
      #|["[3,4,3]"]
    ),
  )
}

///|
test "jq_compat_145: [if empty then 3 else 4 end]" {
  inspect(
    run_jq("[if empty then 3 else 4 end]", "null"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_146: [if 1 then 3,4 else 5 end]" {
  inspect(
    run_jq("[if 1 then 3,4 else 5 end]", "null"),
    content=(
      #|["[3,4]"]
    ),
  )
}

///|
test "jq_compat_147: [if null then 3 else 5,6 end]" {
  inspect(
    run_jq("[if null then 3 else 5,6 end]", "null"),
    content=(
      #|["[5,6]"]
    ),
  )
}

///|
test "jq_compat_148: [if true then 3 end]" {
  inspect(
    run_jq("[if true then 3 end]", "7"),
    content=(
      #|["[3]"]
    ),
  )
}

///|
test "jq_compat_149: [if false then 3 end]" {
  inspect(
    run_jq("[if false then 3 end]", "7"),
    content=(
      #|["[7]"]
    ),
  )
}

///|
test "jq_compat_150: [if false then 3 else . end]" {
  inspect(
    run_jq("[if false then 3 else . end]", "7"),
    content=(
      #|["[7]"]
    ),
  )
}

///|
test "jq_compat_151: [if false then 3 elif false then 4 end]" {
  inspect(
    run_jq("[if false then 3 elif false then 4 end]", "7"),
    content=(
      #|["[7]"]
    ),
  )
}

///|
test "jq_compat_152: [if false then 3 elif false then 4 else . end]" {
  inspect(
    run_jq("[if false then 3 elif false then 4 else . end]", "7"),
    content=(
      #|["[7]"]
    ),
  )
}

///|
test "jq_compat_153: [-if true then 1 else 2 end]" {
  inspect(
    run_jq("[-if true then 1 else 2 end]", "null"),
    content=(
      #|["[-1]"]
    ),
  )
}

///|
test "jq_compat_154: {x: if true then 1 else 2 end}" {
  inspect(
    run_jq("{x: if true then 1 else 2 end}", "null"),
    content=(
      #|["{\"x\":1}"]
    ),
  )
}

///|
test "jq_compat_155: if true then [.] else . end []" {
  inspect(
    run_jq("if true then [.] else . end []", "null"),
    content=(
      #|["null"]
    ),
  )
}

///|
test "jq_compat_156: [.[] | [.foo[] // .bar]]" {
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
test "jq_compat_157: .[] | [.[0] and .[1], .[0] or .[1]]" {
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
test "jq_compat_158: [.[] | not]" {
  inspect(
    run_jq("[.[] | not]", "[1,0,false,null,true,\"hello\"]"),
    content=(
      #|["[false,false,true,true,false,false]"]
    ),
  )
}

///|
test "jq_compat_159: [10 > 0, 10 > 10, 10 > 20, 10 < 0, 10 < 10, 10 < 20]" {
  inspect(
    run_jq("[10 > 0, 10 > 10, 10 > 20, 10 < 0, 10 < 10, 10 < 20]", "{}"),
    content=(
      #|["[true,false,false,false,false,true]"]
    ),
  )
}

///|
test "jq_compat_160: [10 >= 0, 10 >= 10, 10 >= 20, 10 <= 0, 10 <= 10, 10 <= 20]" {
  inspect(
    run_jq("[10 >= 0, 10 >= 10, 10 >= 20, 10 <= 0, 10 <= 10, 10 <= 20]", "{}"),
    content=(
      #|["[true,true,false,false,true,true]"]
    ),
  )
}

///|
test "jq_compat_161: [ 10 == 10, 10 != 10, 10 != 11, 10 == 11]" {
  inspect(
    run_jq("[ 10 == 10, 10 != 10, 10 != 11, 10 == 11]", "{}"),
    content=(
      #|["[true,false,true,false]"]
    ),
  )
}

///|
test "jq_compat_162: [\"hello\" == \"hello\", \"hello\" != \"hello\", \"hello\" == \"world\"," {
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
test "jq_compat_163: [[1,2,3] == [1,2,3], [1,2,3] != [1,2,3], [1,2,3] == [4,5,6]," {
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
test "jq_compat_164: [{\"foo\":42} == {\"foo\":42},{\"foo\":42} != {\"foo\":42}, {\"foo\":4" {
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
test "jq_compat_165: [{\"foo\":[1,2,{\"bar\":18},\"world\"]} == {\"foo\":[1,2,{\"bar\":18}," {
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
test "jq_compat_166: [(\"foo\" | contains(\"foo\")), (\"foobar\" | contains(\"foo\")), (\"" {
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
test "jq_compat_167: [contains(\"\"), contains(\"\\u0000\")]" {
  inspect(
    run_jq("[contains(\"\"), contains(\"\\u0000\")]", "\"\\u0000\""),
    content=(
      #|["[true,false]"]
    ),
  )
}

///|
test "jq_compat_168: [contains(\"\"), contains(\"a\"), contains(\"ab\"), contains(\"c\")," {
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
test "jq_compat_169: [contains(\"cd\"), contains(\"b\\u0000\"), contains(\"ab\\u0000\")]" {
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
test "jq_compat_170: [contains(\"b\\u0000c\"), contains(\"b\\u0000cd\"), contains(\"b\\u0" {
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
test "jq_compat_171: [contains(\"@\"), contains(\"\\u0000@\"), contains(\"\\u0000what\")]" {
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
test "jq_compat_172: [.[]|(.a, .a)?]" {
  inspect(
    run_jq("[.[]|(.a, .a)?]", "[null,true,{\"a\":1}]"),
    content=(
      #|["[null,null,1,1]"]
    ),
  )
}

///|
test "jq_compat_173: [[.[]|[.a,.a]]?]" {
  inspect(
    run_jq("[[.[]|[.a,.a]]?]", "[null,true,{\"a\":1}]"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_174: [if error then 1 else 2 end?]" {
  inspect(
    run_jq("[if error then 1 else 2 end?]", "\"foo\""),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_175: try error(0) // 1" {
  inspect(
    run_jq("try error(0) // 1", "null"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_176: 1, try error(2), 3" {
  inspect(
    run_jq("1, try error(2), 3", "null"),
    content=(
      #|["1", "3"]
    ),
  )
}

///|
test "jq_compat_177: 1 + try 2 catch 3 + 4" {
  inspect(
    run_jq("1 + try 2 catch 3 + 4", "null"),
    content=(
      #|["7"]
    ),
  )
}

///|
test "jq_compat_178: [-try .]" {
  inspect(
    run_jq("[-try .]", "1"),
    content=(
      #|["[-1]"]
    ),
  )
}

///|
test "jq_compat_179: try -.? catch ." {
  inspect(
    run_jq("try -.? catch .", "\"foo\""),
    content=(
      #|["\"string (\\\"foo\\\") cannot be negated\""]
    ),
  )
}

///|
test "jq_compat_180: {x: try 1, y: try error catch 2, z: if true then 3 end}" {
  inspect(
    run_jq("{x: try 1, y: try error catch 2, z: if true then 3 end}", "null"),
    content=(
      #|["{\"x\":1,\"y\":2,\"z\":3}"]
    ),
  )
}

///|
test "jq_compat_181: {x: 1 + 2, y: false or true, z: null // 3}" {
  inspect(
    run_jq("{x: 1 + 2, y: false or true, z: null // 3}", "null"),
    content=(
      #|["{\"x\":3,\"y\":true,\"z\":3}"]
    ),
  )
}

///|
test "jq_compat_182: .[] | try error catch ." {
  inspect(
    run_jq(".[] | try error catch .", "[1,null,2]"),
    content=(
      #|["1", "null", "2"]

    ),
  )
}

///|
test "jq_compat_183: [.[]|startswith(\"foo\")]" {
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
test "jq_compat_184: [.[]|endswith(\"foo\")]" {
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
test "jq_compat_185: [.[] | split(\", \")]" {
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
test "jq_compat_186: split(\"\")" {
  inspect(
    run_jq("split(\"\")", "\"abc\""),
    content=(
      #|["[\"a\",\"b\",\"c\"]"]
    ),
  )
}

///|
test "jq_compat_187: [.[]|ltrimstr(\"foo\")]" {
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
test "jq_compat_188: [.[]|rtrimstr(\"foo\")]" {
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
test "jq_compat_189: [.[]|trimstr(\"foo\")]" {
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
test "jq_compat_190: [.[]|ltrimstr(\"\")]" {
  inspect(
    run_jq("[.[]|ltrimstr(\"\")]", "[\"a\", \"xx\", \"\"]"),
    content=(
      #|["[\"a\",\"xx\",\"\"]"]
    ),
  )
}

///|
test "jq_compat_191: [.[]|rtrimstr(\"\")]" {
  inspect(
    run_jq("[.[]|rtrimstr(\"\")]", "[\"a\", \"xx\", \"\"]"),
    content=(
      #|["[\"a\",\"xx\",\"\"]"]
    ),
  )
}

///|
test "jq_compat_192: [.[]|trimstr(\"\")]" {
  inspect(
    run_jq("[.[]|trimstr(\"\")]", "[\"a\", \"xx\", \"\"]"),
    content=(
      #|["[\"a\",\"xx\",\"\"]"]
    ),
  )
}

///|
test "jq_compat_193: [(index(\",\"), rindex(\",\")), indices(\",\")]" {
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
test "jq_compat_194: [ index(\"aba\"), rindex(\"aba\"), indices(\"aba\") ]" {
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
test "jq_compat_195: map(trim), map(ltrim), map(rtrim)" {
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
test "jq_compat_196: trim, ltrim, rtrim" {
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
test "jq_compat_197: try trim catch ., try ltrim catch ., try rtrim catch ." {
  inspect(
    run_jq("try trim catch ., try ltrim catch ., try rtrim catch .", "123"),
    content=(
      #|["\"trim input must be a string\"", "\"trim input must be a string\"", "\"trim input must be a string\""]
    ),
  )
}

///|
test "jq_compat_198: indices(1)" {
  inspect(
    run_jq("indices(1)", "[0,1,1,2,3,4,1,5]"),
    content=(
      #|["[1,2,6]"]
    ),
  )
}

///|
test "jq_compat_199: indices([1,2])" {
  inspect(
    run_jq("indices([1,2])", "[0,1,2,3,1,4,2,5,1,2,6,7]"),
    content=(
      #|["[1,8]"]
    ),
  )
}

///|
test "jq_compat_200: indices([1,2])" {
  inspect(
    run_jq("indices([1,2])", "[1]"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_201: indices(\", \")" {
  inspect(
    run_jq("indices(\", \")", "\"a,b, cd,e, fgh, ijkl\""),
    content=(
      #|["[3,9,14]"]
    ),
  )
}

///|
test "jq_compat_202: index(\"!\")" {
  inspect(
    run_jq("index(\"!\")", "\"здравствуй мир!\""),
    content=(
      #|["14"]
    ),
  )
}

///|
test "jq_compat_203: .[:rindex(\"x\")]" {
  inspect(
    run_jq(".[:rindex(\"x\")]", "\"正xyz\""),
    content=(
      #|["\"正\""]
    ),
  )
}

///|
test "jq_compat_204: indices(\"o\")" {
  inspect(
    run_jq("indices(\"o\")", "\"🇬🇧oo\""),
    content=(
      #|["[2,3]"]
    ),
  )
}

///|
test "jq_compat_205: indices(\"o\")" {
  inspect(
    run_jq("indices(\"o\")", "\"ƒoo\""),
    content=(
      #|["[1,2]"]
    ),
  )
}

///|
test "jq_compat_206: [.[]|split(\",\")]" {
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
test "jq_compat_207: [.[]|split(\", \")]" {
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
test "jq_compat_208: [.[] * 3]" {
  inspect(
    run_jq("[.[] * 3]", "[\"a\", \"ab\", \"abc\"]"),
    content=(
      #|["[\"aaa\",\"ababab\",\"abcabcabc\"]"]
    ),
  )
}

///|
test "jq_compat_209: [.[] * \"abc\"]" {
  inspect(
    run_jq("[.[] * \"abc\"]", "[-1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 3.7, 10.0]"),
    content=(
      #|["[null,null,\"\",\"\",\"abc\",\"abc\",\"abcabcabc\",\"abcabcabcabcabcabcabcabcabcabc\"]"]
    ),
  )
}

///|
test "jq_compat_210: . * 100000 | [.[:10],.[-10:]]" {
  inspect(
    run_jq(". * 100000 | [.[:10],.[-10:]]", "\"abc\""),
    content=(
      #|["[\"abcabcabca\",\"cabcabcabc\"]"]
    ),
  )
}

///|
test "jq_compat_211: . * 1000000000" {
  inspect(
    run_jq(". * 1000000000", "\"\""),
    content=(
      #|["\"\""]
    ),
  )
}

///|
test "jq_compat_212: [.[] / \",\"]" {
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
test "jq_compat_213: [.[] / \", \"]" {
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
test "jq_compat_214: map(.[1] as $needle | .[0] | contains($needle))" {
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
test "jq_compat_215: map(.[1] as $needle | .[0] | contains($needle))" {
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
test "jq_compat_216: [({foo: 12, bar:13} | contains({foo: 12})), ({foo: 12} | con" {
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
test "jq_compat_217: {foo: {baz: 12, blap: {bar: 13}}, bar: 14} | contains({bar: " {
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
test "jq_compat_218: {foo: {baz: 12, blap: {bar: 13}}, bar: 14} | contains({bar: " {
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
test "jq_compat_219: sort" {
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
test "jq_compat_220: (sort_by(.b) | sort_by(.a)), sort_by(.a, .b), sort_by(.b, .c" {
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
test "jq_compat_221: unique" {
  inspect(
    run_jq("unique", "[1,2,5,3,5,3,1,3]"),
    content=(
      #|["[1,2,3,5]"]
    ),
  )
}

///|
test "jq_compat_222: unique" {
  inspect(
    run_jq("unique", "[]"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_223: [min, max, min_by(.[1]), max_by(.[1]), min_by(.[2]), max_by(" {
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
test "jq_compat_224: [min,max,min_by(.),max_by(.)]" {
  inspect(
    run_jq("[min,max,min_by(.),max_by(.)]", "[]"),
    content=(
      #|["[null,null,null,null]"]
    ),
  )
}

///|
test "jq_compat_225: .foo[.baz]" {
  inspect(
    run_jq(".foo[.baz]", "{\"foo\":{\"bar\":4},\"baz\":\"bar\"}"),
    content=(
      #|["4"]
    ),
  )
}

///|
test "jq_compat_226: to_entries" {
  inspect(
    run_jq("to_entries", "{\"a\": 1, \"b\": 2}"),
    content=(
      #|["[{\"key\":\"a\",\"value\":1},{\"key\":\"b\",\"value\":2}]"]
    ),
  )
}

///|
test "jq_compat_227: from_entries" {
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
test "jq_compat_228: map(has(\"foo\"))" {
  inspect(
    run_jq("map(has(\"foo\"))", "[{\"foo\": 42}, {}]"),
    content=(
      #|["[true,false]"]
    ),
  )
}

///|
test "jq_compat_229: map(has(2))" {
  inspect(
    run_jq("map(has(2))", "[[0,1], [\"a\",\"b\",\"c\"]]"),
    content=(
      #|["[false,true]"]
    ),
  )
}

///|
test "jq_compat_230: keys" {
  inspect(
    run_jq("keys", "[42,3,35]"),
    content=(
      #|["[0,1,2]"]
    ),
  )
}

///|
test "jq_compat_231: [][.]" {
  inspect(
    run_jq("[][.]", "1000000000000000000"),
    content=(
      #|["null"]
    ),
  )
}

///|
test "jq_compat_232: map([1,2][0:.])" {
  inspect(
    run_jq("map([1,2][0:.])", "[-1, 1, 2, 3, 1000000000000000000]"),
    content=(
      #|["[[1],[1],[1,2],[1,2],[1,2]]"]
    ),
  )
}

///|
test "jq_compat_233: {\"k\": {\"a\": 1, \"b\": 2}} * ." {
  inspect(
    run_jq("{\"k\": {\"a\": 1, \"b\": 2}} * .", "{\"k\": {\"a\": 0,\"c\": 3}}"),
    content=(
      #|["{\"k\":{\"a\":0,\"b\":2,\"c\":3}}"]
    ),
  )
}

///|
test "jq_compat_234: {\"k\": {\"a\": 1, \"b\": 2}, \"hello\": {\"x\": 1}} * ." {
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
test "jq_compat_235: {\"k\": {\"a\": 1, \"b\": 2}, \"hello\": 1} * ." {
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
test "jq_compat_236: {\"a\": {\"b\": 1}, \"c\": {\"d\": 2}, \"e\": 5} * ." {
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
test "jq_compat_237: [.[]|arrays]" {
  inspect(
    run_jq("[.[]|arrays]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[[],[3,[]]]"]
    ),
  )
}

///|
test "jq_compat_238: [.[]|objects]" {
  inspect(
    run_jq("[.[]|objects]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[{}]"]
    ),
  )
}

///|
test "jq_compat_239: [.[]|iterables]" {
  inspect(
    run_jq("[.[]|iterables]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[[],[3,[]],{}]"]
    ),
  )
}

///|
test "jq_compat_240: [.[]|scalars]" {
  inspect(
    run_jq("[.[]|scalars]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[1,2,\"foo\",true,false,null]"]
    ),
  )
}

///|
test "jq_compat_241: [.[]|values]" {
  inspect(
    run_jq("[.[]|values]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[1,2,\"foo\",[],[3,[]],{},true,false]"]
    ),
  )
}

///|
test "jq_compat_242: [.[]|booleans]" {
  inspect(
    run_jq("[.[]|booleans]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[true,false]"]
    ),
  )
}

///|
test "jq_compat_243: [.[]|nulls]" {
  inspect(
    run_jq("[.[]|nulls]", "[1,2,\"foo\",[],[3,[]],{},true,false,null]"),
    content=(
      #|["[null]"]
    ),
  )
}

///|
test "jq_compat_244: flatten" {
  inspect(
    run_jq("flatten", "[0, [1], [[2]], [[[3]]]]"),
    content=(
      #|["[0,1,2,3]"]
    ),
  )
}

///|
test "jq_compat_245: try flatten(-1) catch ." {
  inspect(
    run_jq("try flatten(-1) catch .", "[0, [1], [[2]], [[[3]]]]"),
    content=(
      #|["\"flatten depth must not be negative\""]
    ),
  )
}

///|
test "jq_compat_246: transpose" {
  inspect(
    run_jq("transpose", "[[1], [2,3]]"),
    content=(
      #|["[[1,2],[null,3]]"]
    ),
  )
}

///|
test "jq_compat_247: transpose" {
  inspect(
    run_jq("transpose", "[]"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_248: ascii_upcase" {
  inspect(
    run_jq("ascii_upcase", "\"useful but not for é\""),
    content=(
      #|["\"USEFUL BUT NOT FOR é\""]
    ),
  )
}

///|
test "jq_compat_249: bsearch(0,1,2,3,4)" {
  inspect(
    run_jq("bsearch(0,1,2,3,4)", "[1,2,3]"),
    content=(
      #|["-1", "0", "1", "2", "-4"]
    ),
  )
}

///|
test "jq_compat_250: bsearch({x:1})" {
  inspect(
    run_jq("bsearch({x:1})", "[{ \"x\": 0 },{ \"x\": 1 },{ \"x\": 2 }]"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_251: try [\"OK\", bsearch(0)] catch [\"KO\",.]" {
  inspect(
    run_jq("try [\"OK\", bsearch(0)] catch [\"KO\",.]", "\"aa\""),
    content=(
      #|["[\"KO\",\"string (\\\"aa\\\") cannot be searched from\"]"]
    ),
  )
}

///|
test "jq_compat_252: try strflocaltime(\"%Y-%m-%dT%H:%M:%SZ\") catch ." {
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
test "jq_compat_253: try [\"OK\", strflocaltime({})] catch [\"KO\", .]" {
  inspect(
    run_jq("try [\"OK\", strflocaltime({})] catch [\"KO\", .]", "0"),
    content=(
      #|["[\"KO\",\"unknown function: strflocaltime\"]"]
    ),
  )
}

///|
test "jq_compat_254: modulemeta | .deps | length" {
  inspect(
    run_jq("modulemeta | .deps | length", "\"c\""),
    content=(
      #|["ERROR: unknown function: modulemeta"]
    ),
  )
}

///|
test "jq_compat_255: modulemeta | .defs | length" {
  inspect(
    run_jq("modulemeta | .defs | length", "\"c\""),
    content=(
      #|["ERROR: unknown function: modulemeta"]
    ),
  )
}

///|
test "jq_compat_256: try -. catch ." {
  inspect(
    run_jq("try -. catch .", "\"very-long-long-long-long-string\""),
    content=(
      #|["\"string (\\\"very-long-...) cannot be negated\""]
    ),
  )
}

///|
test "jq_compat_257: \"x\" * range(0; 12; 2) + \"☆\" * 8 | try -. catch ." {
  inspect(
    run_jq("\"x\" * range(0; 12; 2) + \"☆\" * 8 | try -. catch .", "null"),
    content=(
      #|["\"string (\\\"☆☆☆☆☆☆☆☆\\\") cannot be negated\"", "\"string (\\\"xx☆☆☆☆☆☆☆☆\\\") cannot be negated\"", "\"string (\\\"xxxx☆☆☆☆☆☆...) cannot be negated\"", "\"string (\\\"xxxxxx☆☆☆☆...) cannot be negated\"", "\"string (\\\"xxxxxxxx☆☆...) cannot be negated\"", "\"string (\\\"xxxxxxxxxx...) cannot be negated\""]
    ),
  )
}

///|
test "jq_compat_258: join(\",\")" {
  inspect(
    run_jq("join(\",\")", "[\"1\",2,true,false,3.4]"),
    content=(
      #|["\"1,2,true,false,3.4\""]
    ),
  )
}

///|
test "jq_compat_259: .[] | join(\",\")" {
  inspect(
    run_jq(".[] | join(\",\")", "[[], [null], [null,null], [null,null,null]]"),
    content=(
      #|["\"\"", "\"\"", "\",\"", "\",,\""]
    ),
  )
}

///|
test "jq_compat_260: .[] | join(\",\")" {
  inspect(
    run_jq(".[] | join(\",\")", "[[\"a\",null], [null,\"a\"]]"),
    content=(
      #|["\"a,\"", "\",a\""]
    ),
  )
}

///|
test "jq_compat_261: try join(\",\") catch ." {
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
test "jq_compat_262: try join(\",\") catch ." {
  inspect(
    run_jq("try join(\",\") catch .", "[\"1\",\"2\",[3,4,5]]"),
    content=(
      #|["\"string (\\\"1,2,\\\") and array ([3,4,5]) cannot be added\""]
    ),
  )
}

///|
test "jq_compat_263: JOIN({\"0\":[0,\"abc\"],\"1\":[1,\"bcd\"],\"2\":[2,\"def\"],\"3\":[3,\"efg\"" {
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
test "jq_compat_264: range(5;10)|IN(range(10))" {
  inspect(
    run_jq("range(5;10)|IN(range(10))", "null"),
    content=(
      #|["true", "true", "true", "true", "true"]
    ),
  )
}

///|
test "jq_compat_265: range(5;13)|IN(range(0;10;3))" {
  inspect(
    run_jq("range(5;13)|IN(range(0;10;3))", "null"),
    content=(
      #|["false", "true", "false", "false", "true", "false", "false", "false"]
    ),
  )
}

///|
test "jq_compat_266: range(10;12)|IN(range(10))" {
  inspect(
    run_jq("range(10;12)|IN(range(10))", "null"),
    content=(
      #|["false", "false"]
    ),
  )
}

///|
test "jq_compat_267: IN(range(10;20); range(10))" {
  inspect(
    run_jq("IN(range(10;20); range(10))", "null"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_268: IN(range(5;20); range(10))" {
  inspect(
    run_jq("IN(range(5;20); range(10))", "null"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_269: isempty(empty)" {
  inspect(
    run_jq("isempty(empty)", "null"),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_270: isempty(range(3))" {
  inspect(
    run_jq("isempty(range(3))", "null"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_271: isempty(1,error(\"foo\"))" {
  inspect(
    run_jq("isempty(1,error(\"foo\"))", "null"),
    content=(
      #|["false"]
    ),
  )
}

///|
test "jq_compat_272: index(\"\")" {
  inspect(
    run_jq("index(\"\")", "\"\""),
    content=(
      #|["0"]
    ),
  )
}

///|
test "jq_compat_273: map(. == 1)" {
  inspect(
    run_jq("map(. == 1)", "[1, 1.0, 1.000, 100e-2, 1e+0, 0.0001e4]"),
    content=(
      #|["[true,true,true,true,true,true]"]
    ),
  )
}

///|
test "jq_compat_274: .[0] | tostring | . == if have_decnum then \"1391186036643239" {
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
test "jq_compat_275: .x | tojson | . == if have_decnum then \"13911860366432393\" e" {
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
test "jq_compat_276: (13911860366432393 == 13911860366432392) | . == if have_decn" {
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
test "jq_compat_277: . - 10" {
  inspect(
    run_jq(". - 10", "13911860366432393"),
    content=(
      #|["Infinity"]
    ),
  )
}

///|
test "jq_compat_278: .[0] - 10" {
  inspect(
    run_jq(".[0] - 10", "[13911860366432393]"),
    content=(
      #|["Infinity"]
    ),
  )
}

///|
test "jq_compat_279: .x - 10" {
  inspect(
    run_jq(".x - 10", "{\"x\":13911860366432393}"),
    content=(
      #|["Infinity"]
    ),
  )
}

///|
test "jq_compat_280: -. | tojson == if have_decnum then \"-13911860366432393\" else" {
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
test "jq_compat_281: -. | tojson == if have_decnum then \"0.1234567890123456789012" {
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
test "jq_compat_282: .[] as $n | $n+0 | [., tostring, . == $n]" {
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
test "jq_compat_283: abs" {
  inspect(
    run_jq("abs", "\"abc\""),
    content=(
      #|["\"abc\""]
    ),
  )
}

///|
test "jq_compat_284: map(abs)" {
  inspect(
    run_jq("map(abs)", "[-0, 0, -10, -1.1]"),
    content=(
      #|["[0,0,10,1.1]"]
    ),
  )
}

///|
test "jq_compat_285: map(fabs)" {
  inspect(
    run_jq("map(fabs)", "[-0, 0, -10, -1.1]"),
    content=(
      #|["[0,0,10,1.1]"]
    ),
  )
}

///|
test "jq_compat_286: map(abs == length) | unique" {
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
test "jq_compat_287: map(abs)" {
  inspect(
    run_jq("map(abs)", "[0.1,1000000000000000002]"),
    content=(
      #|["[0.1,Infinity]"]
    ),
  )
}

///|
test "jq_compat_288: reduce .[] as $then (4 as $else | $else; . as $elif | . + $t" {
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
test "jq_compat_289: 1 as $foreach | 2 as $and | 3 as $or | { $foreach, $and, $or" {
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
test "jq_compat_290: 1 as $x | \"2\" as $y | \"3\" as $z | { $x, as, $y: 4, ($z): 5, " {
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
test "jq_compat_291: fromjson | isnan" {
  inspect(
    run_jq("fromjson | isnan", "\"nan\""),
    content=(
      #|["true"]
    ),
  )
}

///|
test "jq_compat_292: tojson | fromjson" {
  inspect(
    run_jq("tojson | fromjson", "{\"a\":nan}"),
    content=(
      #|["ERROR: invalid JSON input"]
    ),
  )
}

///|
test "jq_compat_293: first(.?,.?)" {
  inspect(
    run_jq("first(.?,.?)", "null"),
    content=(
      #|["null"]
    ),
  )
}

///|
test "jq_compat_294: any(keys[]|tostring?;true)" {
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
test "jq_compat_295: implode|explode" {
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
test "jq_compat_296: map(try implode catch .)" {
  inspect(
    run_jq("map(try implode catch .)", "[123,[\"a\"],[nan]]"),
    content=(
      #|["ERROR: invalid JSON input"]
    ),
  )
}

///|
test "jq_compat_297: walk(.)" {
  inspect(
    run_jq("walk(.)", "{\"x\":0}"),
    content=(
      #|["{\"x\":0}"]
    ),
  )
}

///|
test "jq_compat_298: walk(1)" {
  inspect(
    run_jq("walk(1)", "{\"x\":0}"),
    content=(
      #|["1"]
    ),
  )
}

///|
test "jq_compat_299: [walk(.,1)]" {
  inspect(
    run_jq("[walk(.,1)]", "{\"x\":0}"),
    content=(
      #|["[{\"x\":0},1]"]
    ),
  )
}

///|
test "jq_compat_300: walk(select(IN({}, []) | not))" {
  inspect(
    run_jq("walk(select(IN({}, []) | not))", "{\"a\":1,\"b\":[]}"),
    content=(
      #|["{\"a\":1}"]
    ),
  )
}

///|
test "jq_compat_301: [range(10)] | .[1.2:3.5]" {
  inspect(
    run_jq("[range(10)] | .[1.2:3.5]", "null"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "jq_compat_302: [range(10)] | .[1.5:3.5]" {
  inspect(
    run_jq("[range(10)] | .[1.5:3.5]", "null"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "jq_compat_303: [range(10)] | .[1.7:3.5]" {
  inspect(
    run_jq("[range(10)] | .[1.7:3.5]", "null"),
    content=(
      #|["[1,2,3]"]
    ),
  )
}

///|
test "jq_compat_304: [range(10)] | .[1.7:4294967295]" {
  inspect(
    run_jq("[range(10)] | .[1.7:4294967295]", "null"),
    content=(
      #|["[1,2,3,4,5,6,7,8,9]"]
    ),
  )
}

///|
test "jq_compat_305: [range(10)] | .[1.7:-4294967296]" {
  inspect(
    run_jq("[range(10)] | .[1.7:-4294967296]", "null"),
    content=(
      #|["[]"]
    ),
  )
}

///|
test "jq_compat_306: [[range(10)] | .[1.1,1.5,1.7]]" {
  inspect(
    run_jq("[[range(10)] | .[1.1,1.5,1.7]]", "null"),
    content=(
      #|["[1,1,1]"]
    ),
  )
}

///|
test "jq_compat_307: try fromjson catch ." {
  inspect(
    run_jq("try fromjson catch .", "\"{'a': 123}\""),
    content=(
      #|["\"invalid JSON string\""]
    ),
  )
}

///|
test "jq_compat_308: try ltrimstr(1) catch \"x\", try rtrimstr(1) catch \"x\" | \"ok\"" {
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
test "jq_compat_309: try ltrimstr(\"x\") catch \"x\", try rtrimstr(\"x\") catch \"x\" | \"" {
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
test "jq_compat_310: foreach .[] as $x (0, 1; . + $x)" {
  inspect(
    run_jq("foreach .[] as $x (0, 1; . + $x)", "[1, 2]"),
    content=(
      #|["2", "4"]
    ),
  )
}

///|
test "jq_compat_311: strflocaltime(\"\" | ., @uri)" {
  inspect(
    run_jq("strflocaltime(\"\" | ., @uri)", "0"),
    content=(
      #|["ERROR: unknown function: strflocaltime"]
    ),
  )
}

///|
test "jq_compat_312: reduce range(9999) as $_ ([];[.]) | tojson | fromjson | flat" {
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
test "jq_compat_313: reduce range(10001) as $_ ([];[.]) | tojson | contains(\"<ski" {
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
