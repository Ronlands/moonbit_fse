///| 比较不同大小的编码

test "compare_50_60_70" {
  println("=== 比较50/60/70字节编码 ===\n")
  
  let sizes = [50, 60, 70]
  
  for size in sizes {
    let test_data : Array[Byte] = []
    for i = 0; i < size; i = i + 1 {
      test_data.push((i % 3).to_byte())
    }
    let data = Bytes::from_array(test_data)
    
    // 统计符号
    let mut c0 = 0
    let mut c1 = 0
    let mut c2 = 0
    for i = 0; i < size; i = i + 1 {
      match data[i].to_int() {
        0 => c0 = c0 + 1
        1 => c1 = c1 + 1
        2 => c2 = c2 + 1
        _ => ()
      }
    }
    
    println("大小" + size.to_string() + ":")
    println("  符号分布: 0=" + c0.to_string() + ", 1=" + c1.to_string() + ", 2=" + c2.to_string())
    
    // 计算理论位数
    // 假设最高频率符号用1位，其他用2位
    let max_freq = if c0 >= c1 && c0 >= c2 {
      c0
    } else if c1 >= c2 {
      c1
    } else {
      c2
    }
    let other_total = size - max_freq
    let theory_bits = max_freq * 1 + other_total * 2
    let theory_bytes = (theory_bits + 7) / 8
    println("  理论压缩位数: " + theory_bits.to_string() + " (" + theory_bytes.to_string() + "字节)")
    
    let options = @username/moonbit_fse/src.create_default_huffman_options()
    let result = @username/moonbit_fse/src.huffman_compress_advanced(data, options)
    
    match result {
      @username/moonbit_fse/src.CompressionResult::Success(compressed) => {
        println("  实际压缩: " + compressed.length().to_string() + "字节")
        
        // 尝试解压缩
        let decomp_result = @username/moonbit_fse/src.huffman_decompress_advanced(compressed)
        match decomp_result {
          @username/moonbit_fse/src.CompressionResult::Success(decompressed) => {
            if decompressed.length() == size {
              let mut errors = 0
              for i = 0; i < size; i = i + 1 {
                if data[i] != decompressed[i] {
                  errors = errors + 1
                }
              }
              if errors == 0 {
                println("  解压缩: ✓ 完全匹配")
              } else {
                println("  解压缩: ✗ " + errors.to_string() + "个错误")
              }
            } else {
              println("  解压缩: ✗ 长度不匹配")
            }
          }
          @username/moonbit_fse/src.CompressionResult::Error(msg) => {
            println("  解压缩: ✗ 失败 - " + msg)
          }
          _ => {
            println("  解压缩: ✗ 意外结果")
          }
        }
      }
      _ => {
        println("  压缩失败")
      }
    }
    println("")
  }
}


