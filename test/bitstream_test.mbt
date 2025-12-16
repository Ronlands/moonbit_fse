///|
/// 位流操作测试
test "bitstream_write_read" {
  println("=== 测试位流写入和读取 ===")

  // 测试1：写入和读取单个位
  let stream = @username/moonbit_fse/src.BitCStream::new(10)
  stream.add_bits(1UL, 1) // 写入1位：1
  stream.add_bits(0UL, 1) // 写入1位：0
  stream.add_bits(1UL, 1) // 写入1位：1
  let compressed = stream.close()
  println("压缩后字节数: " + compressed.length().to_string())
  if compressed.length() > 0 {
    println("第一个字节: " + compressed[0].to_int().to_string())
  }

  //读取
  let read_stream = @username/moonbit_fse/src.BitDStream::new(compressed)
  let bit1 = read_stream.read_bits(1)
  let bit2 = read_stream.read_bits(1)
  let bit3 = read_stream.read_bits(1)
  println(
    "读取的位: " +
    bit1.to_int().to_string() +
    ", " +
    bit2.to_int().to_string() +
    ", " +
    bit3.to_int().to_string(),
  )
  if bit1 == 1UL && bit2 == 0UL && bit3 == 1UL {
    println("✓ 位流读写正确！")
  } else {
    println("✗ 位流读写不匹配")
    abort("位流测试失败")
  }
}

///|
test "bitstream_multibit" {
  println("\n=== 测试多位读写 ===")

  // 写入不同长度的编码
  let stream = @username/moonbit_fse/src.BitCStream::new(10)
  stream.add_bits(0UL, 1) // 符号0: 1位编码 "0"
  stream.add_bits(1UL, 1) // 符号1: 1位编码 "1"
  stream.add_bits(0UL, 1) // 符号0: 1位编码 "0"
  let compressed = stream.close()
  println("压缩后字节数: " + compressed.length().to_string())

  // 读取
  let read_stream = @username/moonbit_fse/src.BitDStream::new(compressed)
  let val1 = read_stream.read_bits(1)
  let val2 = read_stream.read_bits(1)
  let val3 = read_stream.read_bits(1)
  println(
    "读取的值: " +
    val1.to_int().to_string() +
    ", " +
    val2.to_int().to_string() +
    ", " +
    val3.to_int().to_string(),
  )
  if val1 == 0UL && val2 == 1UL && val3 == 0UL {
    println("✓ 多位读写正确！")
  } else {
    println("✗ 多位读写不匹配")
    println("期望: 0, 1, 0")
  }
}

