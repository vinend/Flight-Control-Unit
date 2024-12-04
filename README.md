
# ✈️ Flight Control Unit (FCU) - Final Project in Digital System Design

Welcome to the **Flight Control Unit** project repository! This project focuses on designing a flight control system for small Unmanned Aerial Vehicles (UAVs) using VHDL. It includes the implementation of a PID controller and other associated modules for stabilization and navigation of the UAV.

## 🚀 Overview

The **Flight Control Unit (FCU)** serves as the central nervous system for the UAV, receiving input from the computer or microcontroller to control various actuators such as motors and servos. This enables the UAV to achieve the desired trajectory, altitude, and speed. 

The primary component of the FCU is the **PID Controller Module**, which uses the Proportional-Integral-Derivative (PID) algorithm to ensure stable flight. The PID controller adjusts motor speeds to maintain the desired position or velocity, correcting for any errors in real-time.

The FCU also includes multiple **State Machines** to handle different flight phases, including:
- **Idle:** The UAV is in a standby mode.
- **Takeoff:** The UAV starts its ascent.
- **Hover:** The UAV maintains a stable position at a fixed altitude.
- **Cruise:** The UAV flies at a constant altitude and speed.
- **Land:** The UAV descends and prepares to land safely.

The system also integrates **Signal Processing Modules** to process data from various sensors, such as **LiDAR**, which measures altitude and provides real-time feedback to the control system. Based on this data, control signals are generated to adjust the UAV's flight path.

### Key Modules and Features:
1. **PID Controller Module**: Implements the PID logic for flight stability and navigation.
2. **State Machines**: Manage transitions between different flight phases, such as Idle, Takeoff, Hover, Cruise, and Land.
3. **Sensor Processing Unit**: Receives and processes sensor data, such as LiDAR, to determine the UAV’s altitude and assist in maintaining stable flight.
4. **Actuator Control Module**: Sends PWM (Pulse Width Modulation) signals to control the motors, adjusting speed based on the PID output or control commands.
5. **Data Communication**: The FCU communicates with the flight control system through simple communication protocols such as SPI Slave or UART.

The goal of this project is to create a highly responsive and stable flight control system capable of autonomously controlling the UAV's flight dynamics.

## Group Project Members
1. **Andi Muhammad Alvin Farhansyah** - 2306161933 👑💯
2. **Ibnu Zaky Fauzi** - 2306161870
3. **Samih Bassam** - 2306250623
4. **Daffa Bagus Dhinanto** - 2306250756

## 🗂️ Project Structure
