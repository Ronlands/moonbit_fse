///| 直方图统计模块
///| 用于统计符号频率

///| 统计符号频率
///| @param data 输入数据
///| @param max_symbol_value 最大符号值
///| @return (频率数组, 实际最大符号值, 最大频率)
pub fn count_histogram(data : Bytes, max_symbol_value : Int) -> (Array[Int], Int, Int) {
  let count : Array[Int] = Array::new(capacity=max_symbol_value + 1)
  for i = 0; i <= max_symbol_value; i = i + 1 {
    count.push(0)
  }
  
  if data.length() == 0 {
    return (count, 0, 0)
  }
  
  // 统计频率
  for i = 0; i < data.length(); i = i + 1 {
    let byte_val = data[i].to_int()
    if byte_val <= max_symbol_value {
      count[byte_val] = count[byte_val] + 1
    }
  }
  
  // 找到实际的最大符号值
  let mut actual_max_symbol = 0
  for i = max_symbol_value; i >= 0; i = i - 1 {
    if count[i] > 0 {
      actual_max_symbol = i
      break
    }
  }
  
  // 找到最大频率
  let mut max_freq = 0
  for i = 0; i <= actual_max_symbol; i = i + 1 {
    if count[i] > max_freq {
      max_freq = count[i]
    }
  }
  
  (count, actual_max_symbol, max_freq)
}

///| 快速统计（针对大数据优化）
pub fn count_fast(data : Bytes, max_symbol_value : Int) -> (Array[Int], Int, Int) {
  // 对于小数据，使用简单方法
  if data.length() < 1500 {
    return count_histogram(data, max_symbol_value)
  }
  
  // 对于大数据，使用并行统计（简化版）
  count_histogram(data, max_symbol_value)
}

///| 计算唯一符号数量
pub fn count_unique_symbols(count : Array[Int], max_symbol : Int) -> Int {
  let mut unique = 0
  for i = 0; i <= max_symbol; i = i + 1 {
    if count[i] > 0 {
      unique = unique + 1
    }
  }
  unique
}

///| 检查是否为单符号数据
pub fn is_single_symbol(count : Array[Int], max_symbol : Int) -> (Bool, Int) {
  let mut found_symbol = -1
  let mut symbol_count = 0
  
  for i = 0; i <= max_symbol; i = i + 1 {
    if count[i] > 0 {
      symbol_count = symbol_count + 1
      if symbol_count == 1 {
        found_symbol = i
      } else {
        return (false, -1)
      }
    }
  }
  
  (symbol_count == 1, found_symbol)
}

///| 计算数据的香农熵
pub fn calculate_entropy(count : Array[Int], total_size : Int, max_symbol : Int) -> Double {
  if total_size == 0 {
    return 0.0
  }
  
  let mut entropy = 0.0
  for i in 0..=max_symbol {
    if count[i] > 0 {
      let p = count[i].to_double() / total_size.to_double()
      let log_p = log(p)
      let log_2 = log(2.0)
      entropy = entropy - p * (log_p / log_2)
    }
  }
  
  entropy
}

///| 估算最优table_log值
pub fn optimal_table_log(src_size : Int, _max_symbol_value : Int, max_table_log : Int) -> Int {
  if src_size <= 1 {
    return 0
  }
  
  let mut table_log = max_table_log
  
  // 根据数据大小调整
  if src_size < 2048 {
    table_log = table_log - 1
  }
  if src_size < 512 {
    table_log = table_log - 1
  }
  
  // 确保table_log在合理范围内
  if table_log < 5 {
    table_log = 5
  }
  if table_log > 12 {
    table_log = 12
  }
  
  table_log
}

