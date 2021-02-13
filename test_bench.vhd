LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.std_logic_arith.all;

ENTITY test_bench IS
	PORT (
		clk		: OUT	std_logic;
		reset		: OUT	std_logic;
		IV_r		: OUT	std_logic_vector (63 downto 0);
		key_r		: OUT	std_logic_vector (255 downto 0);
		data_out_r	: OUT	std_logic_vector (127 downto 0);
		Key_load	: OUT	std_logic;
		IV_load		: OUT	std_logic;
		data_in_r	: IN	std_logic_vector (127 downto 0);
		Pti_ready	: IN	std_logic;
		Eto_valid	: IN	std_logic;
		Key_lock	: IN	std_logic;
		IV_lock		: IN	std_logic
		);
END ENTITY;

ARCHITECTURE rtl_test OF test_bench IS

CONSTANT period : TIME := 2 ns;
CONSTANT period4 : TIME := 2000000 ns;

BEGIN

clock_process : PROCESS
    BEGIN 
        clk <= '0';
        WAIT FOR period;
        clk <= '1';
        WAIT FOR period;
END PROCESS clock_process;

ciph_process : PROCESS
    BEGIN
    	IV_r <= (others => '0');
    	key_r <= (others => '0');
    	data_out_r <= (others => '0');
    	Key_load <= '0';
    	IV_load <= '0';
    	reset <= '1';
    	wait for 1 ns;
    	reset <= '0';
    	wait for 1 ns;
    	Key_load <= '1';
    	reset <= '0';
    	key_r <= X"8899aabbccddeeff0011223344556677fedcba98765432100123456789abcdef";
        WAIT FOR 4 ns;
    	Key_load <= '0';
    	wait until key_lock = '0';
    	IV_r <= X"1234567890abcef0";
    	IV_load <= '1';
    	WAIT FOR 4 ns;
    	IV_load <= '0';
    	data_out_r <= (others => '0');
    	wait until Pti_ready = '1';
    	wait for 8 ns;
    	data_out_r <= X"1122334455667700ffeeddccbbaa9988";
    	wait for 4 ns;
    	data_out_r <= X"00112233445566778899aabbcceeff0a";
    	wait for 4 ns;
    	data_out_r <= X"112233445566778899aabbcceeff0a00";
    	wait for 4 ns;
    	data_out_r <= X"2233445566778899aabbcceeff0a0011";
    	wait for 4 ns;
    	data_out_r <= X"11111111111111111111111111111111";
    	wait for 4 ns;
    	data_out_r <= (others => '0');
    	WAIT FOR 8 ns;
    	reset <= '1';
    	wait for 1 ns;
    	reset <= '0';
    	Key_load <= '1';
    	key_r <= X"8899aabbccddeeff0011223344556677fedcba98765432100123456789abcdef";
        WAIT FOR 4 ns;
    	Key_load <= '0';
    	wait until key_lock = '0';
    	IV_r <= X"1234567890abcef0";
    	IV_load <= '1';
    	WAIT FOR 4 ns;
    	IV_load <= '0';
    	data_out_r <= (others => '0');
    	wait until Pti_ready = '1';
    	wait for 8 ns;
    	data_out_r <= X"f195d8bec10ed1dbd57b5fa240bda1b8";
    	wait for 4 ns;
    	data_out_r <= X"85eee733f6a13e5df33ce4b33c45dee4";
    	wait for 4 ns;
    	data_out_r <= X"a5eae88be6356ed3d5e877f13564a3a5";
    	wait for 4 ns;
    	data_out_r <= X"cb91fab1f20cbab6d1c6d15820bdba73";
    	wait for 4 ns;
    	data_out_r <= (others => '0');
    	WAIT FOR 8 ns;
 END PROCESS ciph_process;

END rtl_test;

