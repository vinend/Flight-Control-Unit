LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY PID_Controller_tb IS
END PID_Controller_tb;

ARCHITECTURE Behavioral OF PID_Controller_tb IS
    -- Component Declaration
    COMPONENT PID_Controller IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            p_en : IN STD_LOGIC;
            i_en : IN STD_LOGIC;
            d_en : IN STD_LOGIC;
            ref_val : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            adc_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            pwm : OUT STD_LOGIC;
            dbg_out : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
        );
    END COMPONENT;

    -- Test Signals
    SIGNAL clk : std_logic := '0';
    SIGNAL rst : std_logic := '0';
    SIGNAL p_en : std_logic := '0';
    SIGNAL i_en : std_logic := '0';
    SIGNAL d_en : std_logic := '0';
    SIGNAL ref_val : std_logic_vector(11 downto 0) := (others => '0');
    SIGNAL adc_in : std_logic_vector(7 downto 0) := (others => '0');
    SIGNAL pwm : std_logic;
    SIGNAL dbg_out : std_logic_vector(11 downto 0);
    
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
        report "Actual output value: " & integer'image(to_integer(unsigned(dbg_out))) severity note;
        report "Controls: P=" & std_logic'image(p_en) & 
               " I=" & std_logic'image(i_en) & 
               " D=" & std_logic'image(d_en) severity note;
    END PROCEDURE;

BEGIN
    -- DUT instantiation
    UUT: PID_Controller 
    PORT MAP (
        clk => clk,
        rst => rst,
        p_en => p_en,
        i_en => i_en,
        d_en => d_en,
        ref_val => ref_val,
        adc_in => adc_in,
        pwm => pwm,
        dbg_out => dbg_out
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
        rst <= '1';
        wait for CLK_PERIOD*2;

        -- Test Case 1: P control only
        p_en <= '1';
        i_en <= '0';
        d_en <= '0';
        ref_val <= std_logic_vector(to_unsigned(2048, 12));
        adc_in <= std_logic_vector(to_unsigned(128, 8));
        wait for CLK_PERIOD*10;
        print_test_case("P Control Only", 2048, 128, 1024);

        -- Test Case 2: PI control
        p_en <= '1';
        i_en <= '1';
        d_en <= '0';
        ref_val <= std_logic_vector(to_unsigned(3072, 12));
        adc_in <= std_logic_vector(to_unsigned(64, 8));
        wait for CLK_PERIOD*10;
        print_test_case("PI Control", 3072, 64, 2048);

        -- Test Case 3: Full PID
        p_en <= '1';
        i_en <= '1';
        d_en <= '1';
        ref_val <= std_logic_vector(to_unsigned(4000, 12));
        adc_in <= std_logic_vector(to_unsigned(255, 8));
        wait for CLK_PERIOD*10;
        print_test_case("Full PID", 4000, 255, 3000);

        -- Test Case 4: System Reset
        rst <= '0';
        wait for CLK_PERIOD*5;
        print_test_case("System Reset", 4000, 255, 0);

        -- Test Case 5: Integral Windup Test
        rst <= '1';
        p_en <= '0';
        i_en <= '1';
        d_en <= '0';
        ref_val <= std_logic_vector(to_unsigned(4095, 12));
        adc_in <= std_logic_vector(to_unsigned(0, 8));
        wait for CLK_PERIOD*20;
        print_test_case("Integral Windup Test", 4095, 0, 4000);

        report "=== Test Complete ===" severity note;
        wait;
    END PROCESS;

END Behavioral;