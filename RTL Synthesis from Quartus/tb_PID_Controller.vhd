LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tb_PID_Controller IS
END tb_PID_Controller;

ARCHITECTURE behavior OF tb_PID_Controller IS

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT PID_Controller
        GENERIC (
            N : INTEGER := 16  -- number of bits of PWM counter
        );
        PORT (
            kp_sw : IN std_logic;
            ki_sw : IN std_logic;
            kd_sw : IN std_logic;
            SetVal : IN std_logic_vector(11 DOWNTO 0);
            PWM_PIN : OUT std_logic;
            ADC : IN std_logic_vector(7 DOWNTO 0);
            reset_button : IN std_logic;
            display_output : OUT std_logic_vector(11 DOWNTO 0);
            clk : IN std_logic;
            anode_activate : OUT std_logic_vector(3 DOWNTO 0);
            led_out : OUT std_logic_vector(6 DOWNTO 0)
        );
    END COMPONENT;

    -- Signals for connecting to UUT
    SIGNAL kp_sw : std_logic := '0';
    SIGNAL ki_sw : std_logic := '0';
    SIGNAL kd_sw : std_logic := '0';
    SIGNAL SetVal : std_logic_vector(11 DOWNTO 0) := (others => '0');
    SIGNAL PWM_PIN : std_logic;
    SIGNAL ADC : std_logic_vector(7 DOWNTO 0) := (others => '0');
    SIGNAL reset_button : std_logic := '0';
    SIGNAL display_output : std_logic_vector(11 DOWNTO 0);
    SIGNAL clk : std_logic := '0';
    SIGNAL anode_activate : std_logic_vector(3 DOWNTO 0);
    SIGNAL led_out : std_logic_vector(6 DOWNTO 0);

    -- Clock period definition
    CONSTANT clk_period : time := 10 ns;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: PID_Controller
        PORT MAP (
            kp_sw => kp_sw,
            ki_sw => ki_sw,
            kd_sw => kd_sw,
            SetVal => SetVal,
            PWM_PIN => PWM_PIN,
            ADC => ADC,
            reset_button => reset_button,
            display_output => display_output,
            clk => clk,
            anode_activate => anode_activate,
            led_out => led_out
        );

    -- Clock process definitions
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- hold reset state for 100 ns.
        reset_button <= '1';
        wait for 100 ns;
        reset_button <= '0';
        
        -- Insert stimulus here
        kp_sw <= '1';
        ki_sw <= '1';
        kd_sw <= '1';
        SetVal <= "000000111111"; -- Example set value
        ADC <= "00001111"; -- Example ADC value

        wait for 200 ns;
        
        -- Change stimulus
        SetVal <= "000001111111";
        ADC <= "00011111";

        wait for 200 ns;

        -- Finish simulation
        wait;
    end process;

END;