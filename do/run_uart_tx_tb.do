# UART Transmitter Testbench Do File
# ModelSim/QuestaSim script for UART TX testing

# Create work library
vlib work
vmap work work

# Compile source files
vlog ./rtl/uart_tx.v

# Compile testbench files
vlog ./tb/uart_tx_tb.v

# Load design
vsim work.uart_tx_tb -voptargs=+acc

# Add waves for monitoring
add wave -noupdate -divider "System Signals"
add wave -noupdate -color Yellow /uart_tx_tb/clk
add wave -noupdate -color Yellow /uart_tx_tb/arst_n
add wave -noupdate -color Yellow /uart_tx_tb/rst

add wave -noupdate -divider "UART TX Signals"
add wave -noupdate -color Cyan /uart_tx_tb/tx_en
add wave -noupdate -color Cyan /uart_tx_tb/tx_data
add wave -noupdate -color Cyan /uart_tx_tb/baudiv
add wave -noupdate -color Green /uart_tx_tb/tx
add wave -noupdate -color Magenta /uart_tx_tb/tx_busy
add wave -noupdate -color Magenta /uart_tx_tb/tx_done

add wave -noupdate -divider "DUT Internal Signals"
add wave -noupdate -color Orange /uart_tx_tb/dut/counter
add wave -noupdate -color Orange /uart_tx_tb/dut/bit_num
add wave -noupdate -color Orange /uart_tx_tb/dut/frame
add wave -noupdate -color Orange /uart_tx_tb/dut/tx

# Configure wave display
configure wave -timelineunits ns
WaveRestoreZoom {0 ps} {1000 ns}

# Run simulation
run -all

# Display results
echo "UART Transmitter Test Completed"
echo "Check transcript for detailed results"
