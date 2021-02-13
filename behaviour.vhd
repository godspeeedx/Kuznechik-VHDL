LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.all;
USE ieee.STD_LOGIC_UNSIGNED.ALL;

ENTITY cipher	IS
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
END ENTITY;

ARCHITECTURE rtl of cipher IS
	TYPE state_type IS (Init, KeyGen, IV, Ciphering);
	TYPE conveyor_state_type is (Waiting, XOR1, S, L, XOR3, NewKeysIter);
	TYPE conveyor_state is array (0 to 17) of conveyor_state_type;
	TYPE memory_cell is array (0 to 15) of std_logic_vector(7 downto 0);
	TYPE memory_cell2 is array (0 to 255) of std_logic_vector (7 downto 0);
	TYPE memory_cell3 is array (0 to 31) of std_logic_vector (127 downto 0);
	TYPE LG_array is array (0 to 17) of std_logic_vector (0 to 3);
	TYPE dummy_array is array (0 to 17) of std_logic_vector (127 downto 0);
	TYPE memory_cell4 is array (0 to 15) of std_logic_vector (127 downto 0);
	
	SIGNAL keys_done, iv_done : std_logic;
	SIGNAL sync_r		: std_logic_vector (127 downto 0);
	SIGNAL keys_r		: memory_cell4;
	SIGNAL state		: state_type;
	SIGNAL conveyor_belt	: conveyor_state;
	SIGNAL iter_keys	: std_logic_vector (255 downto 0);
	SIGNAL dummy_r		: dummy_array;
	SIGNAL keygen_count_1_r	: std_logic_vector (0 to 2);
	SIGNAL keygen_count_2_r	: std_logic_vector (0 to 3);
	SIGNAL L_count_r	: LG_array;
	SIGNAL gamma_count_r	: LG_array;
	SIGNAL conveyor_empty	: std_logic_vector (0 to 17);
	SIGNAL countt		: std_logic_vector (0 to 4);

	
	CONSTANT xor_constants: memory_cell3 := (
	X"6ea276726c487ab85d27bd10dd849401",X"dc87ece4d890f4b3ba4eb92079cbeb02",
	X"b2259a96b4d88e0be7690430a44f7f03",X"7bcd1b0b73e32ba5b79cb140f2551504",
	X"156f6d791fab511deabb0c502fd18105",X"a74af7efab73df160dd208608b9efe06",
	X"c9e8819dc73ba5ae50f5b570561a6a07",X"f6593616e6055689adfba18027aa2a08",
	X"98FB40648A4D2C31F0DC1C90FA2EBE09",X"2ADEDAF23E95A23A17B518A05E61C10A",
	X"447CAC8052DDD8824A92A5B083E5550B",X"8D942D1D95E67D2C1A6710C0D5FF3F0C",
	X"E3365B6FF9AE07944740ADD0087BAB0D",X"5113C1F94D76899FA029A9E0AC34D40E",
	X"3FB1B78B213EF327FD0E14F071B0400F",X"2FB26C2C0F0AACD1993581C34E975410",
	X"41101A5E6342D669C4123CD39313C011",X"F33580C8D79A5862237B38E3375CBF12",
	X"9D97F6BABBD222DA7E5C85F3EAD82B13",X"547F77277CE987742EA93083BCC24114",
	X"3ADD015510A1FDCC738E8D936146D515",X"88F89BC3A47973C794E789A3C509AA16",
	X"E65AEDB1C831097FC9C034B3188D3E17",X"D9EB5A3AE90FFA5834CE2043693D7E18",
	X"B7492C48854780E069E99D53B4B9EA19",X"056CB6DE319F0EEB8E80996310F6951A",
	X"6BCEC0AC5DD77453D3A72473CD72011B",X"A22641319AECD1FD835291039B686B1C",
	X"CC843743F6A4AB45DE752C1346ECFF1D",X"7EA1ADD5427C254E391C2823E2A3801E",
	X"1003DBA72E345FF6643B95333F27141F",X"5EA7D8581E149B61F16AC1459CEDA820"
	);
	
	CONSTANT nonlin_tr: memory_cell2 := (
	X"FC",X"EE",X"DD",X"11",X"CF",X"6E",X"31",X"16",X"FB",X"C4",X"FA",X"DA",X"23",X"C5",X"04",X"4D",
	X"E9",X"77",X"F0",X"DB",X"93",X"2E",X"99",X"BA",X"17",X"36",X"F1",X"BB",X"14",X"CD",X"5F",X"C1",
	X"F9",X"18",X"65",X"5A",X"E2",X"5C",X"EF",X"21",X"81",X"1C",X"3C",X"42",X"8B",X"01",X"8E",X"4F",
	X"05",X"84",X"02",X"AE",X"E3",X"6A",X"8F",X"A0",X"06",X"0B",X"ED",X"98",X"7F",X"D4",X"D3",X"1F",
	X"EB",X"34",X"2C",X"51",X"EA",X"C8",X"48",X"AB",X"F2",X"2A",X"68",X"A2",X"FD",X"3A",X"CE",X"CC",
	X"B5",X"70",X"0E",X"56",X"08",X"0C",X"76",X"12",X"BF",X"72",X"13",X"47",X"9C",X"B7",X"5D",X"87",
	X"15",X"A1",X"96",X"29",X"10",X"7B",X"9A",X"C7",X"F3",X"91",X"78",X"6F",X"9D",X"9E",X"B2",X"B1",
	X"32",X"75",X"19",X"3D",X"FF",X"35",X"8A",X"7E",X"6D",X"54",X"C6",X"80",X"C3",X"BD",X"0D",X"57",
	X"DF",X"F5",X"24",X"A9",X"3E",X"A8",X"43",X"C9",X"D7",X"79",X"D6",X"F6",X"7C",X"22",X"B9",X"03",
	X"E0",X"0F",X"EC",X"DE",X"7A",X"94",X"B0",X"BC",X"DC",X"E8",X"28",X"50",X"4E",X"33",X"0A",X"4A",
	X"A7",X"97",X"60",X"73",X"1E",X"00",X"62",X"44",X"1A",X"B8",X"38",X"82",X"64",X"9F",X"26",X"41",
	X"AD",X"45",X"46",X"92",X"27",X"5E",X"55",X"2F",X"8C",X"A3",X"A5",X"7D",X"69",X"D5",X"95",X"3B",
	X"07",X"58",X"B3",X"40",X"86",X"AC",X"1D",X"F7",X"30",X"37",X"6B",X"E4",X"88",X"D9",X"E7",X"89",
	X"E1",X"1B",X"83",X"49",X"4C",X"3F",X"F8",X"FE",X"8D",X"53",X"AA",X"90",X"CA",X"D8",X"85",X"61",
	X"20",X"71",X"67",X"A4",X"2D",X"2B",X"09",X"5B",X"CB",X"9B",X"25",X"D0",X"BE",X"E5",X"6C",X"52",
	X"59",X"A6",X"74",X"D2",X"E6",X"F4",X"B4",X"C0",X"D1",X"66",X"AF",X"C2",X"39",X"4B",X"63",X"B6"
	);
	
	CONSTANT lin_tr: memory_cell := (
	X"94",X"20",X"85",X"10",X"C2",X"C0",X"01",X"FB",X"01",X"C0",X"C2",X"10",X"85",X"20",X"94",X"01"
	);

function nonlin_transformation (text_in : in std_logic_vector (127 downto 0); const : in memory_cell2) return std_logic_vector is
variable temp, ret		: std_logic_vector(127 downto 0);
begin
	
	for k in 0 to 15 loop
		temp(k*8+7 downto k*8) := const(conv_integer(text_in(k*8+7 downto k*8)));
	end loop;
	
ret:= temp;
return ret;
end nonlin_transformation;

FUNCTION  GF_mult(mult1, mult2, polynomial : in std_logic_vector) RETURN std_logic_vector IS 
VARIABLE dummy          : std_logic;
VARIABLE temp           : std_logic_vector((polynomial'length)-2 downto 0);
VARIABLE ret            : std_logic_vector((polynomial'length)-2 downto 0);
BEGIN
  temp := (others=>'0');
  			   
  for i in 0 to polynomial'length-2 LOOP 
    
    	dummy := temp(polynomial'length-2);  
    	
    	for k in (polynomial'length-2) downto 1 loop
   		temp(k) := temp(k-1) xor (dummy and polynomial(k));
   	end loop;   
    	
    	temp(0) := dummy;
    
    for j in 0 to polynomial'length-2 loop
      temp(j) := temp(j) xor (mult1(j) and mult2(polynomial'length-2-i));
    end loop;
  
  end loop;
  ret := temp;
  RETURN ret;
END GF_mult;

function lin_transformation (data : in std_logic_vector(127 downto 0); const : in memory_cell) return std_logic_vector is
variable temp, ret			: std_logic_vector(127 downto 0);
variable buffer1, buffer2, buffer3	: memory_cell;
variable elemental			: std_logic_vector (7 downto 0);
begin

for i in 0 to 15 loop
	buffer1(i) := data(8*(15-i)+7) & data(8*(15-i)+6) & data(8*(15-i)+5) & data(8*(15-i)+4) & data(8*(15-i)+3) & data(8*(15-i)+2) & data(8*(15-i)+1) & data(8*(15-i));
end loop;
 
		for k in 0 to 15 loop
			buffer2(k) := GF_mult(buffer1(k),const(k),"010000110");
		end loop;
 
		elemental := buffer2(0) xor buffer2(1);
		for l in 2 to 15 loop
			elemental := elemental xor buffer2(l);
		end loop;
 
		for m in 0 to 14 loop
			buffer3(m+1) := buffer1(m);
		end loop;
		buffer3(0) := elemental;
		buffer1 := buffer3;
 
	for p in 0 to 15 loop
		temp((p*8)+7 downto (p*8)) := buffer1(15-p);
	end loop;
	
ret := temp;
return ret;
end lin_transformation;

BEGIN

state_process:
PROCESS (clk, reset)
BEGIN
	IF reset = '1' 
		THEN state <= Init;
	ELSIF (rising_edge(clk)) THEN
		CASE state IS
			WHEN Init =>
			IF Key_load = '1'
				THEN state <= KeyGen;
			END IF;
			WHEN KeyGen =>
			IF keys_done = '1'
				THEN state <= IV;
			END IF;
			WHEN IV =>
			IF Key_load = '1'
				THEN state <= KeyGen;
			ELSIF iv_done = '1'
				THEN state <= Ciphering;
			END IF;
			WHEN Ciphering =>
			IF Key_load = '1'
				THEN state <= KeyGen;
			ELSIF IV_load = '1'
				THEN state <= IV;
			END IF;
		END CASE;
	END IF;
END PROCESS;

conveyor_state_process:
PROCESS (clk, reset)
BEGIN
	IF reset = '1'	THEN
		for k in 0 to 17 loop
		conveyor_belt(k) <= Waiting;
		end loop;
	
	ELSIF (rising_edge(clk)) THEN
		CASE conveyor_belt(0) IS
			WHEN Waiting =>
			IF (state = KeyGen and keygen_count_1_r /= "010" and keygen_count_2_r /= "1000") or (state = Ciphering)
				THEN conveyor_belt(0) <= XOR1;
			END IF;
			WHEN XOR1 =>
			IF IV_load = '1' or Key_load = '1' or (keygen_count_1_r = "011" and keygen_count_2_r = "1000")
				THEN conveyor_belt(0) <= Waiting;
			ELSIF	gamma_count_r(0) = "1001" THEN
				conveyor_belt(0) <= XOR3;
			ELSE
				conveyor_belt(0) <= S;
			END IF;
			WHEN S =>
			IF IV_load = '1' or Key_load = '1' or (keygen_count_1_r = "011" and keygen_count_2_r = "1000")
				THEN conveyor_belt(0) <= Waiting;
			ELSE
				conveyor_belt(0) <= L;
			END IF;
			WHEN L =>
			IF IV_load = '1' or Key_load = '1' or (keygen_count_1_r = "011" and keygen_count_2_r = "1000")
				THEN conveyor_belt(0) <= Waiting;
			ELSIF state = KeyGen and L_count_r(0) >= "1111"
				THEN conveyor_belt(0) <= XOR3;
			ELSIF state = Ciphering and L_count_r(0) >= "1111" THEN
				conveyor_belt(0) <= XOR1;
			END IF;
			WHEN XOR3 =>
			IF IV_load = '1' or Key_load = '1' or (keygen_count_1_r = "011" and keygen_count_2_r = "1000")
				THEN conveyor_belt(0) <= Waiting;
			ELSIF state = KeyGen
				THEN conveyor_belt(0) <= NewKeysIter;
			ELSE
				conveyor_belt(0) <= XOR1;
			END IF;
			WHEN NewKeysIter => 
			IF IV_load = '1' or Key_load = '1' or (keygen_count_1_r = "011" and keygen_count_2_r = "1000")
				THEN conveyor_belt(0) <= Waiting;
			ELSE
				conveyor_belt(0) <= XOR1;
			END IF;
		END CASE;
		for i in 1 to 17 loop
			CASE conveyor_belt(i) IS
				WHEN Waiting =>
				IF conveyor_belt(i-1) = XOR1
					THEN conveyor_belt(i) <= XOR1;
				END IF;
				WHEN XOR1 =>
				IF conveyor_belt(i-1) = Waiting THEN
					conveyor_belt(i) <= Waiting;
				ELSIF	gamma_count_r(i) = "1001" THEN
				conveyor_belt(i) <= XOR3;
				ELSE
				conveyor_belt(i) <= S;
				END IF;
				WHEN S =>
				IF conveyor_belt(i-1) = Waiting THEN
					conveyor_belt(i) <= Waiting;
				ELSE
					conveyor_belt(i) <= L;
				END IF;
				WHEN L =>
				IF conveyor_belt(i-1) = Waiting THEN
					conveyor_belt(i) <= Waiting;
				ELSIF L_count_r(i) >= "1111"
					THEN conveyor_belt(i) <= XOR1;
				END IF;
				WHEN XOR3 =>
				IF conveyor_belt(i-1) = Waiting THEN
					conveyor_belt(i) <= Waiting;
				ELSE
					conveyor_belt(i) <= XOR1;
				END IF;
				WHEN NewKeysIter =>
					conveyor_belt(0) <= NewKeysIter;
			END CASE;
		end loop;
	END IF;
END PROCESS;

signal_process:
PROCESS(clk, reset, state, conveyor_belt)
BEGIN
IF reset = '1' THEN

	for i in 0 to 15 loop
		keys_r(i) <= (others => '0');
	end loop;
	
	for j in 0 to 17 loop
		L_count_r(j) <= (others => '0');
		gamma_count_r(j) <= (others => '0');
		dummy_r(j) <= (others => '0');
	end loop;
	
	keys_done	<= '0';
	iv_done		<= '0';
	Pti_ready 	<= '0';
	Eto_valid 	<= '0';
	Key_lock 	<= '0';
	IV_lock 	<= '0';
	data_out_r	<= (others => '0');
	sync_r 		<= (others => '0');
	iter_keys	<= (others => '0');
	keygen_count_1_r <= (others => '0');
	keygen_count_2_r <= (others => '0');
	conveyor_empty <= (others => '0');
	countt		<= (others => '0');
	
	ELSIF (rising_edge(clk)) THEN
	------------------------------------------------------------------------------

	---------------------------keygen_count_1_r------------------------------------
IF (state = Init or state = IV) THEN
	keygen_count_1_r <= "000";
ELSIF (state = KeyGen) THEN
	IF (conveyor_belt(0) = XOR1) THEN
		IF (keygen_count_2_r >= "1000") THEN
			keygen_count_1_r <= keygen_count_1_r + '1';	
		END IF;
	END IF;
ELSE
	keygen_count_1_r <= keygen_count_1_r;	
END IF;
	-------------------------------------------------------------------------------

	---------------------------keygen_count_2_r------------------------------------
	
IF (state = Init or state = IV) THEN	
	keygen_count_2_r <= "0000";
ELSIF (state = KeyGen) THEN
	IF conveyor_belt(0) = XOR1 and keygen_count_2_r = "1000" 
		THEN keygen_count_2_r <= "0000";
	END IF;
	IF (conveyor_belt(0) = XOR3) THEN
		keygen_count_2_r <= keygen_count_2_r + '1';	
	END IF;
ELSE	
	keygen_count_2_r <= keygen_count_2_r;
END IF;
	-------------------------------------------------------------------------------
	
	-----------------------------L_count-------------------------------------------
for k in 0 to 17 loop
IF (conveyor_belt(k) = Waiting) THEN
		L_count_r(k) <= (others => '0');
ELSIF (conveyor_belt(k) = L) THEN
	IF L_count_r(k) < "1111" THEN
		L_count_r(k) <= L_count_r(k) + '1';
	END IF;
ELSIF (conveyor_belt(k) = XOR1) THEN
		L_count_r(k) <= (others => '0');
ELSE	
		L_count_r(k) <= L_count_r(k);
END IF;

	-------------------------------------------------------------------------------
	
	-------------------------gamma_count-------------------------------------------
IF (conveyor_belt(k) = Waiting) THEN
	gamma_count_r(k) <= (others => '0');
ELSIF (conveyor_belt(k) = L and state = Ciphering) THEN
	IF L_count_r(k) = "1111" THEN
		gamma_count_r(k) <= gamma_count_r(k) + '1';
	END IF;
ELSIF (conveyor_belt(k) = XOR3 and state = Ciphering) THEN
	gamma_count_r(k) <= (others => '0');
ELSE	
		gamma_count_r(k) <= gamma_count_r(k);
END IF;
end loop;

	-------------------------------------------------------------------------------
	
	-------------------------keys_done-------------------------------------------
IF (state = Init) THEN	
	keys_done <= '0';
ELSIF (state = KeyGen) THEN
	IF (conveyor_belt = (Waiting,Waiting,Waiting,Waiting,Waiting,Waiting,Waiting,Waiting,Waiting,Waiting,Waiting,Waiting,Waiting,Waiting,Waiting,Waiting,Waiting,Waiting) and keygen_count_1_r = "011") THEN
		keys_done <= '1';
	END IF;
ELSIF (state = IV) THEN
	keys_done <= '0';
ELSE
	keys_done <= keys_done;
END IF;	
	---------------------------------------------------------------------------
	
	-------------------------iv_done-------------------------------------------
	
IF (state = Init) THEN	
	iv_done <= '0';	
ELSIF (state = IV) THEN	
	IF IV_load = '0' THEN
		iv_done <= '1';
	END IF;
ELSIF (state = Ciphering) THEN
	iv_done <= '0';
ELSE
	iv_done <= iv_done;
END IF;

	---------------------------------------------------------------------------
	
	-------------------------conveyor_empty------------------------------------
IF (state = Init) THEN	
	conveyor_empty <= "000000000000000000";
END IF;	
IF (state = Ciphering or state = KeyGen) THEN
	for k in 0 to 17 loop
		IF conveyor_belt(k) = Waiting THEN
			conveyor_empty(k) <= '0';
		ELSE 
			conveyor_empty(k) <= '1';
		END IF;
	end loop;
END IF;
	---------------------------------------------------------------------------
	
	-------------------------sync_r-------------------------------------------
IF (state = Init) THEN
	sync_r <= (others => '0');
ELSIF (state = IV) THEN
	sync_r(127 downto 64) <= IV_r;
	sync_r(63 downto 0) <= (others => '0');
ELSIF (state = Ciphering and conveyor_belt(0)/= Waiting) THEN
	sync_r <= sync_r + '1';
ELSE
	sync_r <= sync_r;
END IF;	

	---------------------------------------------------------------------------
	
	-------------------------keys_r-------------------------------------------
IF (state = KeyGen) THEN
	IF (keygen_count_2_r = "0000") THEN
		keys_r(2*conv_integer(keygen_count_1_r)) <= iter_keys(255 downto 128);
		keys_r(2*conv_integer(keygen_count_1_r)+1) <= iter_keys(127 downto 0);
	ELSIF (keygen_count_2_r = "1000" and keygen_count_1_r = "011") THEN
		keys_r(2*conv_integer(keygen_count_1_r+1)) <= iter_keys(255 downto 128);
		keys_r(2*conv_integer(keygen_count_1_r+1)+1) <= iter_keys(127 downto 0);
	END IF;
ELSE
	keys_r <= keys_r;
END IF;

	---------------------------------------------------------------------------
	
	----------------------------------iter_keys--------------------------------

IF (state = KeyGen) THEN
	IF (conveyor_belt(0) = Waiting) THEN
		IF keygen_count_1_r = "0000" THEN
		iter_keys <= key_r;
		END IF;
	ELSIF (conveyor_belt(0) = NewKeysIter) THEN
		iter_keys(127 downto 0) <= iter_keys(255 downto 128);
		iter_keys(255 downto 128) <= dummy_r(0);
	END IF;
ELSIF (state = IV) THEN
	iter_keys <= (others => '0');
END IF;

	---------------------------------------------------------------------------
	
	----------------------------------dummy_r--------------------------------
IF (state = KeyGen) THEN
	IF (conveyor_belt(0) = Waiting) THEN
	    dummy_r(0) <= (others => '0');	
    ELSIF (conveyor_belt(0) = XOR1) THEN
	    IF keygen_count_1_r = "011" and keygen_count_2_r = "1000" THEN
		    dummy_r(0) <= dummy_r(0);
	    ELSE
	    dummy_r(0) <= iter_keys(255 downto 128) xor xor_constants(8*conv_integer(keygen_count_1_r)+conv_integer(keygen_count_2_r));
	    END IF;
	ELSIF (conveyor_belt(0) = S) THEN
		dummy_r(0) <= nonlin_transformation(dummy_r(0),nonlin_tr);
	ELSIF (conveyor_belt(0) = L) THEN
		dummy_r(0) <= lin_transformation(dummy_r(0),lin_tr);
 	ELSIF (conveyor_belt(0) = XOR3) THEN
		dummy_r(0) <= dummy_r(0) xor iter_keys(127 downto 0);
	END IF;
END IF;
FOR k in 0 to 17 loop
IF (state = Init) THEN
	dummy_r(k) <= (others => '0');
ELSIF (state = Ciphering) THEN
	IF (conveyor_belt(k) = Waiting) THEN
		dummy_r(k) <= (others => '0');	
	ELSIF (conveyor_belt(k) = XOR1) THEN
		IF gamma_count_r(k) > "0000" THEN
			dummy_r(k) <= dummy_r(k) xor keys_r(conv_integer(gamma_count_r(k))) ;
		ELSE
			dummy_r(k) <= sync_r xor keys_r(conv_integer(gamma_count_r(k)));
		END IF;
	ELSIF (conveyor_belt(k) = S) THEN
		dummy_r(k) <= nonlin_transformation(dummy_r(k),nonlin_tr);
	ELSIF (conveyor_belt(k) = L) THEN
		dummy_r(k) <= lin_transformation(dummy_r(k),lin_tr);
	END IF;
END IF;

end loop;


	----------------------------------------------------------------------------------
	
	-------------------------------Pti_ready-------------------------------------------
for k in 0 to 17 loop
IF (state = Init) THEN
	Pti_ready <= '0';
ELSIF (state = Ciphering) THEN
	IF (Key_load = '1' or IV_load = '1') THEN
		IF keys_done = '0' or iv_done = '0' THEN
			Pti_ready <= '0';
		END IF;
	ELSIF (conveyor_belt(k) = L and L_count_r(k) = "1111" and gamma_count_r(k) = "1000") THEN
			Pti_ready <= '1';
	ELSIF (conveyor_belt(k) = XOR3) THEN
			Pti_ready <= '0';
	END IF;
END IF;
end loop;
	-------------------------------------------------------------------------------

	-------------------------------Eto_valid--------------------------------------

IF (state = Init) THEN
	Eto_valid <= '0';
ELSIF (state = Ciphering) THEN	
		IF (data_in_r /= X"00000000000000000000000000000000") THEN
			Eto_valid <= '1';
		END IF;
		IF (data_in_r = X"00000000000000000000000000000000") THEN
			Eto_valid <= '0';
		END IF;
END IF;


	-------------------------------------------------------------------------------

	--------------------------------Key_lock---------------------------------------
IF (state = Init) THEN
	Key_lock <= '0';
ELSIF (state = KeyGen) THEN
	Key_lock <= '1';
	IF (keys_done = '1') THEN
	key_lock <= '0';
	END IF;
ELSIF (state = IV) THEN
	Key_lock <= '0';
END IF;

	-------------------------------------------------------------------------------

	--------------------------------IV_lock-------------------------------------
	
IF (state = Init) THEN
	IV_lock <= '0';
ELSIF (state = IV) THEN
	IV_lock <= '1';
	IF iv_done = '1' THEN
	IV_lock <= '0';
	END IF;
ELSIF (state = Ciphering) THEN
	IV_lock <= '0';
END IF;	
	
	-------------------------------------------------------------------------------

	--------------------------------data_out_r-------------------------------------
IF (state = Init) THEN
	data_out_r <= (others => '0');
ELSIF (state = Ciphering) THEN
	IF (conveyor_belt(conv_integer(countt)) = XOR3) THEN
		IF countt /= "10001" THEN
		data_out_r <= dummy_r(conv_integer(countt)) xor data_in_r;
		countt <= countt + '1';
		ELSE 
		data_out_r <= dummy_r(conv_integer(countt)) xor data_in_r;
		countt <= "00000";
		END IF;
	END IF;
END IF;

END IF;
END PROCESS signal_process;

end rtl;

