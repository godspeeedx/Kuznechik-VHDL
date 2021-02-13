LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.std_logic_arith.all;

ENTITY master IS
END master;

ARCHITECTURE mashup_rtl of master IS
	SIGNAL master_clk, master_reset, master_Pti_ready, master_Eto_valid, master_Key_lock,master_Key_load, master_IV_lock, master_IV_load : std_logic;
	SIGNAL master_IV : std_logic_vector(63 downto 0);
	SIGNAL master_key : std_logic_vector(255 downto 0);
	SIGNAL master_data_open : std_logic_vector (127 downto 0);
	SIGNAL master_data_ciphered : std_logic_vector (127 downto 0);
	COMPONENT cipher
		PORT(
		clk		: IN	std_logic;
		reset		: IN	std_logic;
		IV_r		: IN	std_logic_vector(63 downto 0);
		key_r		: IN	std_logic_vector(255 downto 0);
		data_in_r	: IN	std_logic_vector(127 downto 0);
		Key_load	: IN	std_logic;
		IV_load		: IN	std_logic;
		data_out_r	: OUT	std_logic_vector(127 downto 0);
		Pti_ready	: OUT	std_logic;
		Eto_valid	: OUT	std_logic;
		Key_lock	: OUT	std_logic;
		IV_lock		: OUT	std_logic
		);
	END COMPONENT;
	
	COMPONENT test_bench
		PORT(
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
	END COMPONENT;
BEGIN
	num1: test_bench port map (
	clk =>		master_clk,
	reset => 	master_reset,
	IV_r => 	master_IV,
	key_r =>	master_key,
	data_in_r =>	master_data_ciphered,
	data_out_r =>	master_data_open,
	Pti_ready =>	master_Pti_ready,
	Eto_valid =>	master_Eto_valid,
	Key_lock =>	master_Key_lock,
	Key_load =>	master_Key_load,
	IV_lock =>	master_IV_lock,
	IV_load =>	master_IV_load
	);
	num2: cipher port map (
	clk =>		master_clk,
	reset =>	master_reset,
	IV_r =>		master_IV,
	key_r =>	master_key,
	data_in_r =>	master_data_open,
	data_out_r =>	master_data_ciphered,
	Pti_ready =>	master_Pti_ready,
	Eto_valid =>	master_Eto_valid,
	Key_lock =>	master_Key_lock,
	Key_load =>	master_Key_load,
	IV_lock =>	master_IV_lock,
	IV_load =>	master_IV_load
	);
END mashup_rtl;





