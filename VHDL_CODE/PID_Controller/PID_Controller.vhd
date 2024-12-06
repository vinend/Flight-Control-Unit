LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY PID_Controller IS
    PORT (
        clk : IN STD_LOGIC;                               -- was clock
        rst : IN STD_LOGIC;                               -- was reset
        p_en : IN STD_LOGIC;                             -- was kp_enable
        i_en : IN STD_LOGIC;                             -- was ki_enable
        d_en : IN STD_LOGIC;                             -- was kd_enable
        ref_val : IN STD_LOGIC_VECTOR(11 DOWNTO 0);      -- was setpoint
        adc_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);        -- was adc_input
        pwm : OUT STD_LOGIC;                             -- was pwm_out
        dbg_out : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)      -- was debug_output
    );
END PID_Controller;

ARCHITECTURE Behavioral OF PID_Controller IS
    -- Constants remain same but renamed
    CONSTANT P_NUM : INTEGER := 20;                       -- was KP_NUM
    CONSTANT P_DEN : INTEGER := 100;                      -- was KP_DEN
    CONSTANT I_NUM : INTEGER := 25;                       -- was KI_NUM
    CONSTANT I_DEN : INTEGER := 100;                      -- was KI_DEN
    CONSTANT D_NUM : INTEGER := 1;                        -- was KD_NUM
    CONSTANT D_DEN : INTEGER := 100;                      -- was KD_DEN
    CONSTANT T_DIV : INTEGER := 100;                      -- was TIME_DIV

    -- Internal signals renamed
    SIGNAL out_val, avg_res : STD_LOGIC_VECTOR(11 DOWNTO 0);    -- was output, average_result
    SIGNAL adc_val : STD_LOGIC_VECTOR(15 DOWNTO 0);             -- was adc_result
    SIGNAL err, err_d, int_sum, err_old : INTEGER := 0;         -- was error, error_diff, integral_term, old_error
    SIGNAL p_val, i_val, d_val : INTEGER := 0;                  -- was p_term, i_term, d_term
    SIGNAL out_sum : INTEGER := 0;                              -- was output_loaded
    SIGNAL trig, conv_rdy : STD_LOGIC := '0';                   -- was trigger_adc, conversion_done
    SIGNAL err_curr, err_prev : STD_LOGIC_VECTOR(31 DOWNTO 0);  -- was std_error, std_old_error
    SIGNAL pwm_val : STD_LOGIC_VECTOR(11 DOWNTO 0);            -- was pwm_duty

    -- Component declarations stay identical
    COMPONENT AnalogConverter
        PORT (
            sys_clock : IN STD_LOGIC;
            start_conv : IN STD_LOGIC;
            conv_done : OUT STD_LOGIC;
            adc_result : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            analog_pins : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT Triggered
        PORT (
            adc_trigger_out : OUT STD_LOGIC;
            clock_in : IN STD_LOGIC
        );
    END COMPONENT;

    COMPONENT PWM_Generator
        PORT (
            enable : IN STD_LOGIC;
            duty_in : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            clock : IN STD_LOGIC;
            pwm_out : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN
    -- Component instantiations with new signal names
    adc_conv : AnalogConverter
    PORT MAP (
        sys_clock => clk,
        start_conv => trig,
        conv_done => conv_rdy,
        adc_result => adc_val,
        analog_pins => adc_in
    );

    trig_gen : Triggered
    PORT MAP (
        adc_trigger_out => trig,
        clock_in => clk
    );

    pwm_gen : PWM_Generator
    PORT MAP (
        enable => rst,
        duty_in => pwm_val,
        clock => clk,
        pwm_out => pwm
    );

    -- Main process
    main_proc : PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '0' THEN
                err <= 0;
                out_sum <= 0;
                pwm_val <= (others => '0');
                dbg_out <= (others => '0');
            ELSE
                -- Calculate error
                err <= to_integer(unsigned(ref_val)) - to_integer(unsigned(adc_val(11 DOWNTO 0)));
                
                -- Calculate P term
                IF p_en = '1' THEN
                    p_val <= (err * P_NUM) / P_DEN;
                ELSE
                    p_val <= 0;
                END IF;

                -- Sum and saturate output
                out_sum <= p_val + i_val + d_val;
                IF out_sum > 4000 THEN
                    pwm_val <= std_logic_vector(to_unsigned(4000, 12));
                ELSIF out_sum < 0 THEN
                    pwm_val <= std_logic_vector(to_unsigned(0, 12));
                ELSE
                    pwm_val <= std_logic_vector(to_unsigned(out_sum, 12));
                END IF;

                dbg_out <= pwm_val;
            END IF;
        END IF;
    END PROCESS;

    -- Integration process
    int_proc : PROCESS(conv_rdy)
    BEGIN
        IF rising_edge(conv_rdy) THEN
            IF i_en = '1' THEN
                int_sum <= int_sum + err;
                IF int_sum > (T_DIV * I_DEN * 4000) / I_NUM THEN
                    int_sum <= (T_DIV * I_DEN * 4000) / I_NUM;
                ELSIF int_sum < 0 THEN
                    int_sum <= 0;
                END IF;
                i_val <= (I_NUM * int_sum) / (T_DIV * I_DEN);
            ELSE
                int_sum <= 0;
                i_val <= 0;
            END IF;
            err_d <= err - err_old;
            err_old <= err;
        END IF;
    END PROCESS;

    -- Derivative process
    deriv_proc : PROCESS(err_d)
    BEGIN
        IF d_en = '1' THEN
            d_val <= ((D_NUM * err_d) * T_DIV) / D_DEN;
        ELSE
            d_val <= 0;
        END IF;
    END PROCESS;

END Behavioral;