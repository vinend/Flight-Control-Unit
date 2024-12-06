LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY PID_Controller IS
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
END PID_Controller;

ARCHITECTURE Behavioral OF PID_Controller IS
    -- Constants
    CONSTANT con_Kp : INTEGER := 20;  -- proportional constant
    CONSTANT con_kp_den : INTEGER := 100;
    CONSTANT con_Kd : INTEGER := 1;  -- differential constant
    CONSTANT con_kd_den : INTEGER := 100;
    CONSTANT con_Ki : INTEGER := 25;  -- integral constant
    CONSTANT con_ki_den : INTEGER := 100;
    CONSTANT divider_for_time : INTEGER := 100;

    -- Signals
    SIGNAL output, average_result : std_logic_vector(11 DOWNTO 0) := (others => '0');
    SIGNAL adc_Data : std_logic_vector(15 DOWNTO 0) := (others => '0');
    SIGNAL Error, Error_difference, integral_term, old_error, p, i, d : INTEGER := 0;
    SIGNAL output_loaded, output_saturation_buffer : INTEGER := 0;
    SIGNAL control_trigger_buffer, adc_trigger_buffer, conversion_complete, integration_trigger : std_logic := '0';
    SIGNAL std_error, std_old_error : std_logic_vector(31 DOWNTO 0) := (others => '0');

    -- Component declarations
    COMPONENT AnalogConverter
        PORT (
            sys_clock : IN STD_LOGIC;
            start_conv : IN std_logic;
            conv_done : OUT std_logic;
            adc_result : OUT std_logic_vector(15 DOWNTO 0);
            analog_pins : IN std_logic_vector(7 DOWNTO 0)
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
            enable : IN std_logic;
            duty_in : IN std_logic_vector(11 DOWNTO 0);
            clock : IN std_logic;
            pwm_out : OUT std_logic
        );
    END COMPONENT;

    COMPONENT average
        PORT (
            average_complete : OUT std_logic;
            ADC_RESULT : IN std_logic_vector(11 DOWNTO 0);
            average_trigger : IN std_logic;
            averaged_adc_result : OUT std_logic_vector(11 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT error_flip_flop
        PORT (
            Error : IN std_logic_vector(31 DOWNTO 0);
            old_error : OUT std_logic_vector(31 DOWNTO 0);
            trigger : IN std_logic
        );
    END COMPONENT;

BEGIN
    -- Component instantiations
    UUT1 : error_flip_flop
        PORT MAP (
            Error => std_error,
            old_error => std_old_error,
            trigger => integration_trigger
        );

    UUT2 : Triggered
        PORT MAP (
            adc_trigger_out => adc_trigger_buffer,
            clock_in => clk
        );

    UUT3 : PWM_Generator
        PORT MAP (
            enable => reset_button,
            duty_in => output,
            clock => clk,
            pwm_out => PWM_PIN
        );

    UUT4 : AnalogConverter
        PORT MAP (
            sys_clock => clk,
            start_conv => adc_trigger_buffer,
            conv_done => conversion_complete,
            adc_result => adc_Data,
            analog_pins => ADC
        );

    UUT5 : average
        PORT MAP (
            average_complete => integration_trigger,
            ADC_RESULT => adc_Data(15 DOWNTO 4),
            average_trigger => conversion_complete,
            averaged_adc_result => average_result
        );

    -- Main PID process
    pid_process: PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset_button = '0' THEN
                Error <= 0;
                Error_difference <= 0;
                integral_term <= 0;
                old_error <= 0;
                p <= 0;
                i <= 0;
                d <= 0;
                output_loaded <= 0;
                output <= (others => '0');
            ELSE
                -- Calculate error
                Error <= to_integer(unsigned(SetVal)) - to_integer(unsigned(average_result));
                
                -- Calculate P term
                IF kp_sw = '1' THEN
                    p <= (con_Kp * Error) / con_kp_den;
                ELSE
                    p <= 0;
                END IF;

                -- Calculate I term
                IF ki_sw = '1' THEN
                    IF integral_term > (divider_for_time * con_ki_den * 4000) / con_Ki THEN
                        integral_term <= (divider_for_time * con_ki_den * 4000) / con_Ki;
                    ELSIF integral_term < 0 THEN
                        integral_term <= 0;
                    ELSE
                        integral_term <= integral_term + Error;
                    END IF;
                    i <= (con_Ki * integral_term) / (divider_for_time * con_ki_den);
                ELSE
                    integral_term <= 0;
                    i <= 0;
                END IF;

                -- Calculate D term
                IF kd_sw = '1' THEN
                    Error_difference <= Error - old_error;
                    d <= (con_Kd * Error_difference * divider_for_time) / con_kd_den;
                ELSE
                    d <= 0;
                END IF;

                -- Sum and saturate output
                output_saturation_buffer <= p + i + d;
                IF output_saturation_buffer < 0 THEN
                    output_loaded <= 0;
                ELSIF output_saturation_buffer > 4000 THEN
                    output_loaded <= 4000;
                ELSE
                    output_loaded <= output_saturation_buffer;
                END IF;

                output <= std_logic_vector(to_unsigned(output_loaded, 12));
                display_output <= output;
                old_error <= Error;
            END IF;
        END IF;
    END PROCESS;

    -- Convert error for display
    std_error <= std_logic_vector(to_signed(Error, 32));
    std_old_error <= std_logic_vector(to_signed(old_error, 32));

END Behavioral;