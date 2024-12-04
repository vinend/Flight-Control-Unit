LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY PID_Controller IS
    PORT (
        clock : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        
        -- Control enables
        kp_enable : IN STD_LOGIC;
        ki_enable : IN STD_LOGIC;
        kd_enable : IN STD_LOGIC;
        
        -- Setpoint and feedback
        setpoint : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        adc_input : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        
        -- Outputs
        pwm_out : OUT STD_LOGIC;
        debug_output : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    );
END PID_Controller;

ARCHITECTURE Behavioral OF PID_Controller IS
    -- Constants for PID gains
    CONSTANT KP_NUM : INTEGER := 20;
    CONSTANT KP_DEN : INTEGER := 100;
    CONSTANT KI_NUM : INTEGER := 25;
    CONSTANT KI_DEN : INTEGER := 100;
    CONSTANT KD_NUM : INTEGER := 1;
    CONSTANT KD_DEN : INTEGER := 100;
    
    -- Internal signals
    SIGNAL error, prev_error : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL integral_sum : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL error_diff : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL adc_result : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL trigger_adc : STD_LOGIC;
    SIGNAL conversion_done : STD_LOGIC;
    SIGNAL pwm_duty : STD_LOGIC_VECTOR(11 DOWNTO 0);

    -- Component declarations
    COMPONENT AnalogConverter
        PORT (
            sys_clock : IN STD_LOGIC;
            start_conv : IN STD_LOGIC;
            conv_done : OUT STD_LOGIC;
            adc_result : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            analog_pins : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT Integration
        PORT (
            ki_numerator : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            ki_denominator : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            time_for_divider : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            integral_on : IN STD_LOGIC;
            trigger : IN STD_LOGIC;
            sum : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            error : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            new_sum : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            error_difference : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            error_for_pid : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
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
    -- ADC instance
    adc_inst : AnalogConverter
    PORT MAP (
        sys_clock => clock,
        start_conv => trigger_adc,
        conv_done => conversion_done,
        adc_result => adc_result,
        analog_pins => adc_input
    );

    -- Trigger generator instance  
    trigger_inst : Triggered
    PORT MAP (
        adc_trigger_out => trigger_adc,
        clock_in => clock
    );

    -- Integration block instance
    integrator : Integration
    PORT MAP (
        ki_numerator => std_logic_vector(to_unsigned(KI_NUM, 16)),
        ki_denominator => std_logic_vector(to_unsigned(KI_DEN, 16)),
        time_for_divider => std_logic_vector(to_unsigned(100, 16)),
        integral_on => ki_enable,
        trigger => conversion_done,
        sum => integral_sum,
        error => error,
        new_sum => integral_sum,
        error_difference => error_diff,
        error_for_pid => error
    );

    -- PWM generator instance
    pwm_gen : PWM_Generator
    PORT MAP (
        enable => reset,
        duty_in => pwm_duty,
        clock => clock,
        pwm_out => pwm_out
    );

    -- Main PID process
    pid_calc : PROCESS(clock)
        VARIABLE p_term, i_term, d_term : INTEGER;
        VARIABLE pid_sum : INTEGER;
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '0' THEN
                p_term := 0;
                i_term := 0;
                d_term := 0;
                pid_sum := 0;
            ELSE
                -- Calculate error
                error <= std_logic_vector(signed(setpoint) - signed(adc_result(15 DOWNTO 4)));
                
                -- Calculate P term
                IF kp_enable = '1' THEN
                    p_term := (to_integer(signed(error)) * KP_NUM) / KP_DEN;
                ELSE
                    p_term := 0;
                END IF;

                -- I term comes from Integration component
                i_term := to_integer(signed(integral_sum));

                -- Calculate D term
                IF kd_enable = '1' THEN
                    d_term := (to_integer(signed(error_diff)) * KD_NUM) / KD_DEN;
                ELSE
                    d_term := 0;
                END IF;

                -- Sum and saturate
                pid_sum := p_term + i_term + d_term;
                IF pid_sum > 4000 THEN
                    pid_sum := 4000;
                ELSIF pid_sum < 0 THEN
                    pid_sum := 0;
                END IF;

                -- Convert to PWM duty cycle
                pwm_duty <= std_logic_vector(to_unsigned(pid_sum, 12));
                debug_output <= std_logic_vector(to_unsigned(pid_sum, 12));
            END IF;
        END IF;
    END PROCESS;

END Behavioral;