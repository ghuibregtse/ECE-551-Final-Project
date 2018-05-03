# ECE-551-Final-Project
Final Project for ECE 551 (Simple Artificial Neural Network)

Github Repository: https://github.com/ghuibregtse/ECE-551-Final-Project

ECE 551 Spring 2018
Professor:          Younghyun Kim

Authors:            Garret Hubiregtse
                    Sean Cohen
                    Austin Wirtz
          
Top File:           snn.sv

Other Files:        snn_tb.sv, snn_core.sv, snn_core_tb.sv, uart_rx.sv,
                    uart_rx_tb.sv, uart_tx.sv, uart_tx_tb.sv, mac.sv, rst_synch.sv,
                    ram_output_unit.sv, ram_hidden_unit.sv, ram_input_unit.sv,
                    rom_output_weight.sv, rom_hidden_weight.sv, rom_act_func_lut.sv

Project Goal:       Using an FPGA, create a Simple Artificial Neural Network(SNN)
                    that is able to read hand written digits (0-9) and determine if the
                    digit is in fact a digit and if it is, what digit it is.
                    
Other Details:      FPGA is a DE0-Nano (Altera FPGA Board)
                    Design is done using the SystemVerilog HDL
