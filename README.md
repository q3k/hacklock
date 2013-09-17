### Introduction

This is the Hackerspace Warsaw electronic lock mk2 project.

Work in progress! This is a prototype for a TP-Link WR703n based hardware
solution - with a I2C bus on which there is a MAX7300 IO expander and a PN532
NFC tag reader. The I2C is software bit-banged by the kernel, drivers for both
the IO expander and the PN532 are written in Lua.

### Overview

The hacklock is mae out of two separate pieces of hardware:

* The main lock unit, which runs Linux on a low-power SoC, has one I2C bus
  to communicate with an NFC reader and some GPIO, and a second I2C bus to 
  communicate with:
* The keypad, which is a 10-key (or more) physical keypad attached externally,
  and is based around and ATMega8 uC (they're cheap!)

### Current hardware status

Right now the project is in a prototype status. The keypad part is nearly
identical to what will be in production, except that the PCB is home-etched.

The main lock part itself is however based on a TP-Link WR703N router with
OpenWRT and a software I2C bus. In the future, it will probably be replaced
woth a custom i.MX233-based 4-layer board.

### Files

* **software/**
   * **main/**  - code for the central unit of the lock
      * **main.lua** - main Lua script
      * lua-libs/ - other Lua libraries
        * mips-bin/ - C libraries compiled for MIPS/OpenWRT
        * luai2c.tar.gz**  - C i2c library source
        * luasha2.tar.gz - C sha2 library source
   * **keypad/** - AVR code for the keypad               
      * Makefile - the makefile for the keypad firmware
* **hardware/**
   * keypad/ - KiCAD files for the keypad PCB

### Hacking

Feel free to hack around. The whole project, however, is not anywhere near
release, so things will change around and probably make no sense at the moment.
