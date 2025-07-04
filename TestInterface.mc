using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Lang;
using Toybox.Timer;

module Pinion
{
    class TestInterface
    {
        const SIMULATE_TIMEOUT = false;
        const SIMULATE_DISCONNECTION = false;
        const SIMULATE_SLOW_CONNECTION = false;

        const CONNECTION_TIMEOUT = 5000;
        const READWRITE_DELAY = SIMULATE_SLOW_CONNECTION ? 200 : 50;

        private var _delegate as Delegate?;
        private var _scanState as ScanState = NOT_SCANNING;

        private var _foundDevices as Lang.Array<DeviceHandle> = new Lang.Array<DeviceHandle>[0];
        private var _timer as Timer.Timer = new Timer.Timer();

        private var _simulatedReads as Lang.Array<ParameterType> = new Lang.Array<ParameterType>[0];
        private var _simulatedWrites as Lang.Array<ParameterType> = new Lang.Array<ParameterType>[0];

        private var _connectedDevice as Ble.Device?;
        private var _testParameterData as Lang.Dictionary<ParameterType, Lang.Number> =
        {
            HARDWARE_VERSION =>         33554688,
            FIRMWARE_VERSION =>         17563904,
            BOOTLOADER_VERSION =>       33620736,
            SERIAL_NUMBER =>            2480021234l,
            MOUNTING_ANGLE =>           0,
            REAR_TEETH =>               30,
            FRONT_TEETH =>              30,
            WHEEL_CIRCUMFERENCE =>      2231,
            POWER_SUPPLY =>             1,
            CAN_BUS =>                  0,
            DISPLAY =>                  0,
            SPEED_SENSOR_TYPE =>        1,
            NUMBER_OF_MAGNETS =>        1,
            REVERSE_TRIGGER_MAPPING =>  1,
            CURRENT_GEAR =>             1,
            BATTERY_LEVEL =>            7654,
            START_SELECT_GEAR =>        5,
            PRE_SELECT_CADENCE =>       70,
            START_SELECT =>             0,
            PRE_SELECT =>               1,
            NUMBER_OF_GEARS =>          12,
        } as Lang.Dictionary<ParameterType, Lang.Number>;

        public function onConnectionTimeout() as Void
        {
            _connectedDevice = null;

            if(_scanState == SCANNING)
            {
                System.println("Pinion: Timed out connecting, restarting scanning");
            }
            else if(_delegate != null)
            {
                (_delegate as Delegate).onConnectionTimeout();
            }
        }

        public function connect(deviceHandle as DeviceHandle) as Lang.Boolean
        {
            stopScan();

            if(!SIMULATE_TIMEOUT)
            {
                _connectedDevice = new Ble.Device();
                _timer.start(method(:onConnected), SIMULATE_SLOW_CONNECTION ? 5000 : 1500, false);
            }
            else
            {
                _timer.start(method(:onConnectionTimeout), CONNECTION_TIMEOUT, false);
            }

            return true;
        }

        public function isConnected() as Lang.Boolean
        {
            return _connectedDevice != null;
        }

        public function disconnect() as Void
        {
            if(_connectedDevice != null)
            {
                onDisconnected();
            }
        }

        public function startScan() as Void
        {
            if(_scanState == SCANNING)
            {
                return;
            }

            disconnect();
            _scanState = SCANNING;
            onScanStateChanged();

            if(_foundDevices.size() == 0)
            {
                _foundDevices.add(new DeviceHandle(2480021234l, null));
                _foundDevices.add(new DeviceHandle(2480025678l, null));
            }

            _timer.start(method(:onFoundDevicesChanged), 1000, true);
        }

        public function stopScan() as Void
        {
            if(_scanState == NOT_SCANNING)
            {
                return;
            }

            _timer.stop();
            _foundDevices = new Lang.Array<Pinion.DeviceHandle>[0];

            disconnect();
            _scanState = NOT_SCANNING;
            onScanStateChanged();
        }

        public function foundDevices() as Lang.Array<DeviceHandle> { return _foundDevices; }

        public function _simulateReads() as Void
        {
            if(_simulatedReads.size() == 0)
            {
                return;
            }

            var parameter = _simulatedReads[0];
            _simulatedReads.remove(parameter);
            onParameterRead(parameter, _testParameterData[parameter] as Lang.Number);

            if(_simulatedReads.size() > 0)
            {
                _timer.start(method(:_simulateReads), READWRITE_DELAY, false);
            }
            else
            {
                simulateDisconnection();
            }
        }

        public function read(parameter as ParameterType) as Void
        {
            if(parameter == Pinion.BATTERY_LEVEL && (_testParameterData[parameter] as Lang.Number) > 0)
            {
                // Simulate battery draining
                var newValue = (_testParameterData[parameter] as Lang.Number) - 200;
                _testParameterData[parameter] = newValue < 0 ? 0 : newValue;
            }

            _simulatedReads.add(parameter);
            _timer.start(method(:_simulateReads), READWRITE_DELAY, false);
        }

        public function _simulateWrites() as Void
        {
            if(_simulatedWrites.size() == 0)
            {
                return;
            }

            var parameter = _simulatedWrites[0];
            _simulatedWrites.remove(parameter);
            onParameterWrite(parameter, _testParameterData[parameter] as Lang.Number);

            if(_simulatedWrites.size() > 0)
            {
                _timer.start(method(:_simulateWrites), READWRITE_DELAY, false);
            }
            else
            {
                simulateDisconnection();
            }
        }

        public function write(parameter as ParameterType, value as Lang.Number) as Void
        {
            _testParameterData[parameter] = value;
            _simulatedWrites.add(parameter);
            _timer.start(method(:_simulateWrites), READWRITE_DELAY, false);
        }

        public function blockRead(parameter as ParameterType) as Void
        {
            onBlockRead([0, 1, 2]b, 3, 9);
            onBlockRead([3, 4, 5]b, 6, 9);
            onBlockRead([6, 7, 8]b, 9, 9);
        }

        function getActiveErrors() as Void
        {
            onActiveErrorsRetrieved([1234]);
        }

        public function setDelegate(delegate as Delegate) as Void
        {
            _delegate = delegate;
        }

        public function onScanStateChanged() as Void
        {
            if(_delegate != null)
            {
                (_delegate as Delegate).onScanStateChanged(_scanState);
            }
        }

        public function onFoundDevicesChanged() as Void
        {
            if(_delegate != null)
            {
                (_delegate as Delegate).onFoundDevicesChanged(_foundDevices);
            }
        }

        private function simulateDisconnection() as Void
        {
            if(SIMULATE_DISCONNECTION)
            {
                _timer.start(method(:disconnect), 10000, false);
            }
        }

        public function onConnected() as Void
        {
            if(_delegate != null)
            {
                (_delegate as Delegate).onConnected(_connectedDevice as Ble.Device);
            }
        }

        public function onDisconnected() as Void
        {
            if(_connectedDevice != null)
            {
                _connectedDevice = null;
                if(_delegate != null)
                {
                    (_delegate as Delegate).onDisconnected();
                }
            }
        }

        public function onParameterRead(parameter as ParameterType, value as Lang.Number) as Void
        {
            if(_delegate != null)
            {
                (_delegate as Delegate).onParameterRead(parameter, value);
            }
        }

        public function onParameterWrite(parameter as ParameterType, value as Lang.Number) as Void
        {
            if(parameter == HIDDEN_SETTINGS_ENABLE)
            {
                // No point in notifying this
                return;
            }

            if(_delegate != null)
            {
                (_delegate as Delegate).onParameterWrite(parameter, value);
            }
        }

        public function onBlockRead(bytes as Lang.ByteArray, cumulative as Lang.Number, total as Lang.Number) as Void
        {
            if(_delegate != null)
            {
                (_delegate as Delegate).onBlockRead(bytes, cumulative, total);
            }
        }

        public function onActiveErrorsRetrieved(activeErrors as Lang.Array<Lang.Number>) as Void
        {
            if(_delegate != null)
            {
                (_delegate as Delegate).onActiveErrorsRetrieved(activeErrors);
            }
        }
    }
}