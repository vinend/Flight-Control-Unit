LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AnalogConverter IS
    PORT (
        sys_clock    : IN STD_LOGIC;
        start_conv   : IN std_logic;
        conv_done    : out std_logic;
        adc_result   : OUT std_logic_vector (15 DOWNTO 0);
        analog_pins  : IN STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
END AnalogConverter;

ARCHITECTURE Behavioral OF AnalogConverter IS
    -- Signal declarations
    SIGNAL data_out : std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL mux_addr : std_logic_vector(4 DOWNTO 0) := (OTHERS => '0');
    SIGNAL chan_sel : std_logic_vector(4 DOWNTO 0) := (OTHERS => '0');
    SIGNAL aux_neg : std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL aux_pos : std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');

    -- XADC Component Declaration
    COMPONENT XADC
        GENERIC (
            INIT_40 : bit_vector := X"0000";
            INIT_41 : bit_vector := X"0000";
            INIT_42 : bit_vector := X"0800";
            INIT_48 : bit_vector := X"0000";
            INIT_49 : bit_vector := X"0000";
            INIT_4A : bit_vector := X"0000";
            INIT_4B : bit_vector := X"0000";
            INIT_4C : bit_vector := X"0000";
            INIT_4D : bit_vector := X"0000";
            INIT_4E : bit_vector := X"0000";
            INIT_4F : bit_vector := X"0000";
            INIT_50 : bit_vector := X"0000";
            INIT_51 : bit_vector := X"0000";
            INIT_52 : bit_vector := X"0000";
            INIT_53 : bit_vector := X"0000";
            INIT_54 : bit_vector := X"0000";
            INIT_55 : bit_vector := X"0000";
            INIT_56 : bit_vector := X"0000";
            INIT_57 : bit_vector := X"0000";
            INIT_58 : bit_vector := X"0000";
            INIT_5C : bit_vector := X"0000";
            SIM_DEVICE : string := "7SERIES";
            SIM_MONITOR_FILE : string := "design.txt"
        );
        PORT (
            DADDR : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
            DCLK : IN STD_LOGIC;
            DEN : IN STD_LOGIC;
            DI : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            DWE : IN STD_LOGIC;
            RESET : IN STD_LOGIC;
            VAUXN : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            VAUXP : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            CONVST : IN STD_LOGIC;
            CONVSTCLK : IN STD_LOGIC;
            VN : IN STD_LOGIC;
            VP : IN STD_LOGIC;
            DO : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            DRDY : OUT STD_LOGIC;
            EOC : OUT STD_LOGIC;
            EOS : OUT STD_LOGIC;
            BUSY : OUT STD_LOGIC;
            CHANNEL : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
            JTAGLOCKED : OUT STD_LOGIC;
            JTAGMODIFIED : OUT STD_LOGIC;
            JTAGBUSY : OUT STD_LOGIC;
            ALM : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            OT : OUT STD_LOGIC;
            MUXADDR : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
        );
    END COMPONENT;

BEGIN
    adc_result <= data_out;

    -- Analog input mapping
    aux_pos(6) <= analog_pins(0);
    aux_neg(6) <= analog_pins(4);
    aux_pos(14) <= analog_pins(1);
    aux_neg(14) <= analog_pins(5);
    aux_pos(7) <= analog_pins(2);
    aux_neg(7) <= analog_pins(6);
    aux_pos(15) <= analog_pins(3);
    aux_neg(15) <= analog_pins(7);

    XADC_inst : XADC
        GENERIC MAP(
            -- Same INIT values as original
            INIT_40 => X"9000",
            INIT_41 => X"2ef0",
            INIT_42 => X"0800",
            INIT_48 => X"4701",
            INIT_49 => X"00CC",
            INIT_4A => X"0000",
            INIT_4B => X"0000",
            INIT_4C => X"0000",
            INIT_4D => X"00CC",
            INIT_4E => X"0000",
            INIT_4F => X"0000",
            INIT_50 => X"b5ed",
            INIT_51 => X"5999",
            INIT_52 => X"A147",
            INIT_53 => X"dddd",
            INIT_54 => X"a93a",
            INIT_55 => X"5111",
            INIT_56 => X"91Eb",
            INIT_57 => X"ae4e",
            INIT_58 => X"5999",
            INIT_5C => X"5111",
            SIM_DEVICE => "7SERIES",
            SIM_MONITOR_FILE => "design.txt"
        )
        PORT MAP(
            ALM => OPEN,
            OT => OPEN,
            BUSY => OPEN,
            CHANNEL => chan_sel,
            EOC => OPEN,
            EOS => OPEN,
            JTAGBUSY => OPEN,
            JTAGLOCKED => OPEN,
            JTAGMODIFIED => OPEN,
            MUXADDR => mux_addr,
            VAUXN => aux_neg,
            VAUXP => aux_pos,
            CONVST => start_conv,
            CONVSTCLK => '0',
            RESET => '0',
            VN => '0',
            VP => '0',
            DO => data_out,
            DRDY => conv_done,
            DADDR => "0010110",
            DCLK => sys_clock,
            DEN => '1',
            DI => (OTHERS => '0'),
            DWE => '0'
        );
END Behavioral;