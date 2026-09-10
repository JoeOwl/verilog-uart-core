// Q1) Array Partition
module partition_tb;
  int arr[] = '{9,7,4,6,2,8,6,5};
  int even[$];
  int odd[$];

  initial begin
    foreach (arr[i]) begin
      if (arr[i] % 2 == 0) even.push_back(arr[i]);
      else                 odd.push_back(arr[i]);
    end

    $display("Orig. Array : %p", arr);
    $display("Even Array     : %p", even_q);
    $display("Odd Array     : %p", odd_q);
  end
endmodule


// Q2) MAX. Consecutive Number
module max_consecutive_tb;
  int arr[] = '{1,1,0,1,1,1,1,0,0,0,1};
  int max_count, cur_count;
  int max_val,   cur_val;

  initial begin
    max_count = 1;
    cur_count = 1;
    max_val  = arr[0];

    for (int i = 1; i < arr.size(); i++) begin
      if (arr[i] == arr[i-1]) 
        cur_count++;
      else
        cur_count = 1;

      if (cur_count > max_count) begin
        max_count = cur_count;
        max_val = arr[i];
      end
    end

    $display("Array : %p", arr);
    $display("MAX. consecutive number : %0d --> %0d", max_val, max_count);
  end
endmodule


// Q3) Second Max Number without sort()
module second_max_tb;
  int arr[] = '{45,34,67,89,78};
  int max1, max2;

  initial begin
    max1 = {1'b1,0};
    max2 = {1'b1,0};

    foreach (arr[i]) begin
      if (arr[i] > max1) begin
        max2 = max1;
        max1 = arr[i];
      end
      else if (arr[i] > max2 && arr[i] != max1) begin
        max2 = arr[i];
      end
    end

    $display("Array: %p", arr);
    $display("Max value : %0d", max1);
    $display("Second Max value : %0d", max2);
  end
endmodule


// Q4) Frequency Counter
module freq_counter_tb;
  int arr[] = '{8,3,3,4,5,6,3,5,4,6,8,7,6,4,3,5,6};
  int freq[int];
  initial begin
    foreach (arr[i]) freq[arr[i]]++;

    $display("Array: %p", arr);
    $display("Frequency Counter:");
    foreach (freq[key])
      $display("Element %0d repeated %0d time(s)", key, freq[key]);
  end
endmodule
