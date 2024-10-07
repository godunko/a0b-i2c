--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Generalized API of the I2C peripheral controllers and abstract device
--  driver. Support of the I2C peripheral controller for particual MCU is
--  provided by the board support crates. Few implementations of common
--  cases of the device drivers is provided in children packages.

pragma Restrictions (No_Elaboration_Code);

with System;

with A0B.Types;

package A0B.I2C
  with Preelaborate
is

   type Unsigned_8_Array is
     array (A0B.Types.Unsigned_32 range <>) of A0B.Types.Unsigned_8;

   type Device_Address is mod 2**10;

   type Buffer_Descriptor is record
      Address      : System.Address;
      Size         : A0B.Types.Unsigned_32;
      Transferred  : A0B.Types.Unsigned_32;
      State        : A0B.Operation_Status;
      Acknowledged : Boolean;
   end record;
   --  Descriptor of the transmit/receive buffer.
   --
   --  @component Address       Address of the first byte of the buffer memory
   --  @component Size          Size of the buffer in bytes
   --  @component Transferred   Number of byte transferred by the operation
   --  @component State         State of the operation
   --  @component Acknowledged  Whether last transferred byte has been
   --                           acknowledged

   type Buffer_Descriptor_Array is
     array (A0B.Types.Unsigned_32 range <>) of aliased Buffer_Descriptor;

   type Abstract_I2C_Device_Driver is tagged;

   type I2C_Device_Driver_Access is
     access all Abstract_I2C_Device_Driver'Class;

   type I2C_Bus_Master is limited interface;

   not overriding procedure Start
     (Self    : in out I2C_Bus_Master;
      Device  : not null I2C_Device_Driver_Access;
      Success : in out Boolean) is abstract;
   --  Lock the bus to be used by the given slave device, and send START
   --  condition. When the bus is already locked, and slave device is the
   --  same with that locks the bus initially, ReSTART condition will be sent.
   --
   --  @param Self    Bus controller.
   --  @param Device  I2C device to do transfer.
   --  @param Success
   --    On input it specify whether operation should be processed.
   --    On output it returns whether operation has been initiated.

   not overriding procedure Write
     (Self    : in out I2C_Bus_Master;
      Device  : not null I2C_Device_Driver_Access;
      Buffers : in out Buffer_Descriptor_Array;
      Stop    : Boolean;
      Success : in out Boolean) is abstract;
   --  Initiate write operation on the bus. Bus must be locked by the given
   --  device. When requested by the call of Start, or transfer direction
   --  changes, ReSTART condition is sent.
   --
   --  This operation is asynchronous. Associated slave device driver will be
   --  notified on completion of the data transfer.
   --
   --  Some implementations of peripheral controllers hardware need to know
   --  the total amount of the data to be transferred before start of the
   --  transfer. So, it is recommended to prepare all necessary data to be
   --  transferred before requesting of the operation.
   --
   --  @param Self     Bus controller.
   --  @param Device   I2C device to do transfer.
   --  @param Buffers  Buffers to load data to be transmitted to the device.
   --  @param Status   Operation status.
   --  @param Stop     Release bus after transfer completion.
   --  @param Success
   --    On input it specify whether operation should be processed.
   --    On output it returns whether operation has been initiated.

   not overriding procedure Read
     (Self    : in out I2C_Bus_Master;
      Device  : not null I2C_Device_Driver_Access;
      Buffers : in out Buffer_Descriptor_Array;
      Stop    : Boolean;
      Success : in out Boolean) is abstract;
   --  Initiate read operation on the bus. Bus must be locked by the locked by
   --  the given device. When transfer direction changes, ReSTART condition is
   --  sent.
   --
   --  This operation is asynchronous. Associated slave device driver will be
   --  notified on completion of the data transfer.
   --
   --  @param Self     Bus controller.
   --  @param Device   I2C device to do transfer.
   --  @param Buffers  Buffers to load data to be transmitted to the device.
   --  @param Status   Operation status.
   --  @param Stop     Release bus after transfer completion.
   --  @param Success
   --    On input it specify whether operation should be processed.
   --    On output it returns whether operation has been initiated.

   not overriding procedure Stop
     (Self    : in out I2C_Bus_Master;
      Device  : not null I2C_Device_Driver_Access;
      Success : in out Boolean) is abstract;
   --  Request release of the bus locked by the given device and to send STOP
   --  condition. Slave must be equal to value provided to Start procedure.
   --
   --  This operation is asynchronous. Associated slave device driver will be
   --  notified on completion of the transaction.
   --
   --  It can be called immediately after the call of Read/Write to request
   --  end of transaction when current operation has been completed.
   --  Associated slave device driver will be notified on both completion
   --  of the transfer and completion of the transaction.
   --
   --  @param Self    Bus controller.
   --  @param Device  I2C device to do transfer.
   --  @param Success
   --    On input it specify whether operation should be processed.
   --    On output it returns whether operation has been initiated.

   type Abstract_I2C_Device_Driver is abstract tagged limited private;

   not overriding function Target_Address
     (Self : Abstract_I2C_Device_Driver) return Device_Address is abstract;

private

   type Abstract_I2C_Device_Driver is
     abstract tagged limited null record;

   not overriding procedure On_Transfer_Completed
     (Self : in out Abstract_I2C_Device_Driver) is null;

   not overriding procedure On_Transaction_Completed
     (Self : in out Abstract_I2C_Device_Driver) is null;

end A0B.I2C;
