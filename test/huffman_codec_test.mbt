///|
/// 测试Huffman编码/解码表构建
test "huffman_code_table_build" {
  println("=== 测试Huffman编码表构建 ===")

  // 创建简单的频率表：两个符号，频率相同
  let count : Array[Int] = []
  count.push(10) // 符号0出现10次
  count.push(10) // 符号1出现10次
  let max_symbol = 1

  // 调用内部函数构建Huffman编码（这里需要通过压缩来间接测试）
  // 创建测试数据
  let test_data : Array[Byte] = []
  for i = 0; i < 10; i = i + 1 {
    test_data.push(0)
  }
  for i = 0; i < 10; i = i + 1 {
    test_data.push(1)
  }
  let data = Bytes::from_array(test_data)
  println("测试数据: 10个0, 10个1")
  println("数据长度: " + data.length().to_string())

  // 压缩
  let options = @username/moonbit_fse/src.create_default_huffman_options()
  let result = @username/moonbit_fse/src.huffman_compress_advanced(
    data, options,
  )
  match result {
    @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
      println("✓ 压缩成功，长度: " + compressed.length().to_string())

      // 手动解析头部
      println("\n头部信息:")
      println("  标记: 0x" + compressed[0].to_int().to_string())
      println("  max_symbol: " + compressed[1].to_int().to_string())
      let length = (compressed[2].to_int() << 24) |
        (compressed[3].to_int() << 16) |
        (compressed[4].to_int() << 8) |
        compressed[5].to_int()
      println("  原始长度: " + length.to_string())

      // 读取码长
      let max_sym = compressed[1].to_int()
      println("\n码长:")
      for i = 0; i <= max_sym; i = i + 1 {
        let code_length = compressed[6 + i].to_int()
        println(
          "  符号" + i.to_string() + ": " + code_length.to_string() + "位",
        )
      }

      // 计算头部大小和数据起始位置
      let header_size = 6 + max_sym + 1
      println("\n头部大小: " + header_size.to_string())
      println("压缩数据起始: " + header_size.to_string())
      println(
        "压缩数据长度: " + (compressed.length() - header_size).to_string(),
      )
      if compressed.length() > header_size {
        println("前几个压缩字节:")
        let mut bytes_str = "  "
        for i = 0; i < 4 && header_size + i < compressed.length(); i = i + 1 {
          bytes_str = bytes_str +
            compressed[header_size + i].to_int().to_string() +
            " "
        }
        println(bytes_str)
      }

      // 现在尝试解压缩
      println("\n开始解压缩...")
      let decompressed_result = @username/moonbit_fse/src.huffman_decompress_advanced(
        compressed,
      )
      match decompressed_result {
        @username/moonbit_fse/src.CompressionResult::Success(decompressed) => {
          println("✓ 解压缩成功！")
          println("  解压缩长度: " + decompressed.length().to_string())

          // 验证内容
          let mut match_count = 0
          for i = 0; i < data.length() && i < decompressed.length(); i = i + 1 {
            if data[i] == decompressed[i] {
              match_count = match_count + 1
            }
          }
          println(
            "  匹配字节数: " +
            match_count.to_string() +
            "/" +
            data.length().to_string(),
          )
        }
        @username/moonbit_fse/src.CompressionResult::Error(msg) =>
          println("✗ 解压缩失败: " + msg)
        _ => println("✗ 解压缩返回意外结果")
      }
    }
    @username/moonbit_fse/src.CompressionResult::NotCompressible => {
      println("数据不可压缩")
      abort("不应该不可压缩")
    }
    _ => {
      println("✗ 压缩失败")
      abort("压缩失败")
    }
  }
}

