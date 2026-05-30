This project focuses on the assembly and deployment of a low-cost, automated environmental monitoring system using an open-source platform.
The system is built around a Geekcreit Uno R3 microcontroller, which coordinates data collection from two primary sensors:
an Adafruit SHT40 for air temperature and relative humidity (RH), and a Seeed Studio Grove NDIR sensor (Sensirion SCD30) for tracking CO2 levels (as well as air temperature and RH).
To ensure continuous data logging without relying on a constant computer connection, a DFRobot MicroSD module was integrated via SPI, allowing the system to automatically write timestamps,
climate readings from both sensors, and carbon dioxide concentrations into a local data.csv file every 30 seconds.

The experimental setup aimed to monitor indoor air quality variations over an extended, continuous period.
The completed station was placed on a desk inside a university office, logging data continuously for three consecutive days during normal, daily occupancy.
By recording simultaneous temperature and humidity measurements from both hardware nodes, this setup provides a practical dataset to observe temporal microclimate trends,
track how human presence directly impacts CO2 accumulation, and compare the baseline readings and operational offsets of the two different sensor models in a real-world environment.
