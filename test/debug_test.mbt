///|
/// 调试测试文件
/// 用于调试压缩算法问题
test "debug_repeated_data" {
  // 使用ASCII字符创建重复数据
  let repeated_data : Array[Byte] = []
  for i = 0; i < 200; i = i + 1 {
    repeated_data.push(65) // ASCII 'A'
  }
  let repeated_bytes = Bytes::from_array(repeated_data)
  println("原始数据长度: " + repeated_bytes.length().to_string())

  // 直接测试RLE压缩逻辑
  let first_byte = repeated_bytes[0]
  let mut is_repeated = true
  for i = 1; i < repeated_bytes.length(); i = i + 1 {
    if repeated_bytes[i] != first_byte {
      is_repeated = false
      break
    }
  }
  println("是否重复数据: " + is_repeated.to_string())
  println("第一个字节: " + first_byte.to_int().to_string())
  println("数据长度: " + repeated_bytes.length().to_string())

  // 手动检查前几个字节
  let mut debug_bytes = "前10个字节: "
  for i = 0; i < repeated_bytes.length() && i < 10; i = i + 1 {
    debug_bytes = debug_bytes + repeated_bytes[i].to_int().to_string() + " "
  }
  println(debug_bytes)
  if is_repeated {
    // 手动实现RLE压缩
    let result : Array[Byte] = []
    result.push(0x01) // RLE标记
    result.push(first_byte)
    let length = repeated_bytes.length()
    if length <= 255 {
      result.push(length.to_byte())
    } else {
      result.push(0xFF) // 特殊标记
      result.push((length / 256).to_byte())
      result.push((length % 256).to_byte())
    }
    let compressed = Bytes::from_array(result)
    println("压缩后长度: " + compressed.length().to_string())

    // 手动实现RLE解压缩
    let repeat_byte = compressed[1]
    let decompressed_length = if compressed[2] == 0xFF {
      compressed[3].to_int() * 256 + compressed[4].to_int()
    } else {
      compressed[2].to_int()
    }
    let decompressed_result : Array[Byte] = []
    for i = 0; i < decompressed_length; i = i + 1 {
      decompressed_result.push(repeat_byte)
    }
    let decompressed = Bytes::from_array(decompressed_result)
    println("解压缩后长度: " + decompressed.length().to_string())

    // 验证解压缩正确性
    if decompressed.length() != repeated_bytes.length() {
      abort(
        "解压缩长度不匹配: 期望 " +
        repeated_bytes.length().to_string() +
        ", 实际 " +
        decompressed.length().to_string(),
      )
    }

    // 验证内容正确性
    for i = 0; i < repeated_bytes.length(); i = i + 1 {
      if repeated_bytes[i] != decompressed[i] {
        abort("解压缩内容不匹配")
      }
    }
    println("重复数据测试通过")
  } else {
    abort("数据不是重复的")
  }
}
