--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Implementation of the I2C slave device driver with 8bit internal register
--  address.
--
--  This driver supports probe, write to and read from register operations on
--  the device.

pragma Restrictions (No_Elaboration_Code);

with A0B.Callbacks;

package A0B.I2C.Device_Drivers_8
  with Preelaborate
is

   subtype Register_Address is A0B.Types.Unsigned_8;

   type Transaction_Status is record
      Written_Octets : A0B.Types.Unsigned_32;
      Read_Octets    : A0B.Types.Unsigned_32;
      State          : A0B.Operation_Status;
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
   --  Device probe operation. It do single write transfer without any
   --  data to check that device acknowledge its device address.

   procedure Write
     (Self         : in out I2C_Device_Driver'Class;
      Address      : Register_Address;
      Buffer       : Unsigned_8_Array;
      Status       : aliased out Transaction_Status;
      On_Completed : A0B.Callbacks.Callback;
      Success      : in out Boolean);
   --  Register write operation. It do single write transfer on the bus,
   --  which includes both register address and data transfer.

   procedure Read
     (Self         : in out I2C_Device_Driver'Class;
      Address      : Register_Address;
      Buffer       : out Unsigned_8_Array;
      Status       : aliased out Transaction_Status;
      On_Completed : A0B.Callbacks.Callback;
      Success      : in out Boolean);
   --  Register read operation. It combines write transfer on the bus to send
   --  register address and read transfer to receive data.

private

   type State is
     (Initial,
      Write,       --  write register address and data
      Write_Read,  --  write register address, read response
      Read);       --  read response

   type I2C_Device_Driver
     (Controller : not null access I2C_Bus_Master'Class;
      Address    : Device_Address) is
   limited new Abstract_I2C_Device_Driver with record
      State          : Device_Drivers_8.State := Initial;
      On_Completed   : A0B.Callbacks.Callback;
      Transaction    : access Transaction_Status;

      Address_Buffer : Unsigned_8_Array (0 .. 0);
      --  Buffer to store register address
      Write_Buffers  : A0B.I2C.Buffer_Descriptor_Array (0 .. 1);
      Read_Buffers   : A0B.I2C.Buffer_Descriptor_Array (0 .. 0);
   end record;

   overriding function Target_Address
     (Self : I2C_Device_Driver) return Device_Address is
       (Self.Address);

   overriding procedure On_Transfer_Completed
     (Self : in out I2C_Device_Driver);

   overriding procedure On_Transaction_Completed
     (Self : in out I2C_Device_Driver);

end A0B.I2C.Device_Drivers_8;
