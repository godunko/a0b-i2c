--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Generic implementation of the I2C slave device driver.
--
--  This driver supports write and write-read transactions on the bus.

pragma Restrictions (No_Elaboration_Code);

with A0B.Callbacks;

package A0B.I2C.Device_Drivers
  with Preelaborate
is

   type Transaction_Status is record
      Written_Octets : A0B.Types.Unsigned_32;
      Read_Octets    : A0B.Types.Unsigned_32;
      State          : Transfer_State;
   end record;

   type I2C_Device_Driver
     (Controller : not null access I2C_Bus_Master'Class;
      Address    : Device_Address) is
     limited new Abstract_I2C_Device_Driver with private
       with Preelaborable_Initialization;

   --  procedure Probe
   --    (Self         : in out I2C_Device_Driver'Class;
   --     Status       : aliased out Transaction_Status;
   --     On_Completed : A0B.Callbacks.Callback;
   --     Success      : in out Boolean);

   procedure Write
     (Self         : in out I2C_Device_Driver'Class;
      Buffer       : Unsigned_8_Array;
      Status       : aliased out Transaction_Status;
      On_Completed : A0B.Callbacks.Callback;
      Success      : in out Boolean);

   procedure Write_Read
     (Self         : in out I2C_Device_Driver'Class;
      Write_Buffer : Unsigned_8_Array;
      Read_Buffer  : out Unsigned_8_Array;
      Status       : aliased out Transaction_Status;
      On_Completed : A0B.Callbacks.Callback;
      Success      : in out Boolean);

   procedure Read
     (Self         : in out I2C_Device_Driver'Class;
      Buffer       : out Unsigned_8_Array;
      Status       : aliased out Transaction_Status;
      On_Completed : A0B.Callbacks.Callback;
      Success      : in out Boolean);

private

   type State is (Initial, Write, Write_Read, Read);

   type I2C_Device_Driver
     (Controller : not null access I2C_Bus_Master'Class;
      Address    : Device_Address) is
   limited new Abstract_I2C_Device_Driver with record
      State         : Device_Drivers.State := Initial;
      On_Completed  : A0B.Callbacks.Callback;
      Transaction   : access Transaction_Status;

      Write_Buffers : A0B.I2C.Buffer_Descriptor_Array (0 .. 0);
      Read_Buffers  : A0B.I2C.Buffer_Descriptor_Array (0 .. 0);
   end record;

   overriding function Target_Address
     (Self : I2C_Device_Driver) return Device_Address is
       (Self.Address);

   overriding procedure On_Transfer_Completed
     (Self : in out I2C_Device_Driver);

   overriding procedure On_Transaction_Completed
     (Self : in out I2C_Device_Driver);

end A0B.I2C.Device_Drivers;
