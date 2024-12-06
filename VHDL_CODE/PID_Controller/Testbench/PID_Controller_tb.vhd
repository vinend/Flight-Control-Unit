LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY PID_Controller_tb IS
END PID_Controller_tb;

ARCHITECTURE Behavioral OF PID_Controller_tb IS
    -- Component Declaration
    COMPONENT PID_Controller IS
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

    -- Test Signals
    SIGNAL clk : std_logic := '0';
    SIGNAL reset_button : std_logic := '0';
    SIGNAL kp_sw : std_logic := '0';
    SIGNAL ki_sw : std_logic := '0';
    SIGNAL kd_sw : std_logic := '0';
    SIGNAL SetVal : std_logic_vector(11 downto 0) := (others => '0');
    SIGNAL ADC : std_logic_vector(7 downto 0) := (others => '0');
    SIGNAL PWM_PIN : std_logic;
    SIGNAL display_output : std_logic_vector(11 downto 0);
    SIGNAL anode_activate : std_logic_vector(3 downto 0);
    SIGNAL led_out : std_logic_vector(6 downto 0);

    CONSTANT CLK_PERIOD : time := 10 ns;

    -- Helper procedure
    PROCEDURE print_test_case(
        test_name : in string;
        ref_value : in integer;
        adc_value : in integer;
        expected_pwm : in integer) IS
    BEGIN
        report "=== Test Case: " & test_name & " ===" severity note;
        report "Reference value: " & integer'image(ref_value) severity note;
        report "ADC input value: " & integer'image(adc_value) severity note;
        report "Expected PWM value: " & integer'image(expected_pwm) severity note;
        report "Actual output value: " & integer'image(to_integer(unsigned(display_output))) severity note;
        report "Controls: P=" & std_logic'image(kp_sw) & 
               " I=" & std_logic'image(ki_sw) & 
               " D=" & std_logic'image(kd_sw) severity note;
    END PROCEDURE;

BEGIN
    -- DUT instantiation
    UUT: PID_Controller 
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

    -- Clock process
    clk_process: PROCESS
    BEGIN
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    END PROCESS;

    -- Stimulus process
    stim_proc: PROCESS
    BEGIN
        wait for 100 ns;
        reset_button <= '1';
        wait for CLK_PERIOD*2;

        -- Test Case 1: P control only
        kp_sw <= '1';
        ki_sw <= '0';
        kd_sw <= '0';
        SetVal <= std_logic_vector(to_unsigned(2048, 12));
        ADC <= std_logic_vector(to_unsigned(128, 8));
        wait for CLK_PERIOD*10;
        print_test_case("P Control Only", 2048, 128, 409);

        -- Test Case 2: PI control
        kp_sw <= '1';
        ki_sw <= '1';
        kd_sw <= '0';
        SetVal <= std_logic_vector(to_unsigned(3072, 12));
        ADC <= std_logic_vector(to_unsigned(64, 8));
        wait for CLK_PERIOD*10;
        print_test_case("PI Control", 3072, 64, 657);

        -- Test Case 3: Full PID
        kp_sw <= '1';
        ki_sw <= '1';
        kd_sw <= '1';
        SetVal <= std_logic_vector(to_unsigned(4000, 12));
        ADC <= std_logic_vector(to_unsigned(255, 8));
        wait for CLK_PERIOD*10;
        print_test_case("Full PID", 4000, 255, 931);

        -- Test Case 4: System Reset
        reset_button <= '0';
        wait for CLK_PERIOD*5;
        print_test_case("System Reset", 4000, 255, 0);

        -- Test Case 5: Integral Windup Test
        reset_button <= '1';
        kp_sw <= '0';
        ki_sw <= '1';
        kd_sw <= '0';
        SetVal <= std_logic_vector(to_unsigned(4095, 12));
        ADC <= std_logic_vector(to_unsigned(0, 8));
        wait for CLK_PERIOD*20;
        print_test_case("Integral Windup Test", 4095, 0, 153);

        report "=== Test Complete ===" severity note;
        wait for CLK_PERIOD;
        std.env.stop;
    END PROCESS;

END Behavioral;