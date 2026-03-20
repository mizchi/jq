///|
/// Encode a string to UTF-8 bytes.
fn string_to_utf8(s : String) -> Bytes {
  let buf : Array[Byte] = []
  s
  .iter()
  .each(c => {
    let cp = c.to_int()
    if cp < 0x80 {
      buf.push(cp.to_byte())
    } else if cp < 0x800 {
      buf.push((0xc0 | (cp >> 6)).to_byte())
      buf.push((0x80 | (cp & 0x3f)).to_byte())
    } else if cp < 0x10000 {
      buf.push((0xe0 | (cp >> 12)).to_byte())
      buf.push((0x80 | ((cp >> 6) & 0x3f)).to_byte())
      buf.push((0x80 | (cp & 0x3f)).to_byte())
    } else {
      buf.push((0xf0 | (cp >> 18)).to_byte())
      buf.push((0x80 | ((cp >> 12) & 0x3f)).to_byte())
      buf.push((0x80 | ((cp >> 6) & 0x3f)).to_byte())
      buf.push((0x80 | (cp & 0x3f)).to_byte())
    }
  })
  Bytes::from_array(buf[:])
}

///|
/// Decode UTF-8 bytes into a StringBuilder.
fn utf8_to_string(bytes : Bytes, buf : StringBuilder) -> Unit {
  let len = bytes.length()
  let mut i = 0
  while i < len {
    let b = bytes[i].to_int()
    if b < 0x80 {
      buf.write_char(b.unsafe_to_char())
      i += 1
    } else if b < 0xe0 {
      let cp = ((b & 0x1f) << 6) | (bytes[i + 1].to_int() & 0x3f)
      buf.write_char(cp.unsafe_to_char())
      i += 2
    } else if b < 0xf0 {
      let cp = ((b & 0x0f) << 12) |
        ((bytes[i + 1].to_int() & 0x3f) << 6) |
        (bytes[i + 2].to_int() & 0x3f)
      buf.write_char(cp.unsafe_to_char())
      i += 3
    } else {
      let cp = ((b & 0x07) << 18) |
        ((bytes[i + 1].to_int() & 0x3f) << 12) |
        ((bytes[i + 2].to_int() & 0x3f) << 6) |
        (bytes[i + 3].to_int() & 0x3f)
      buf.write_char(cp.unsafe_to_char())
      i += 4
    }
  }
}
