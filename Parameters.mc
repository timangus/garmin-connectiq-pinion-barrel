using Toybox.Lang;

module Pinion
{
    enum ParameterType
    {
        HARDWARE_VERSION,
        FIRMWARE_VERSION,
        BOOTLOADER_VERSION,
        SERIAL_NUMBER,

        REVERSE_TRIGGER_MAPPING,

        CURRENT_GEAR,
        BATTERY_LEVEL,

        START_SELECT_GEAR,
        PRE_SELECT_CADENCE,
        START_SELECT,
        PRE_SELECT,

        NUMBER_OF_GEARS,
    }

    const PARAMETERS =
    {
        HARDWARE_VERSION =>         { :name => "HARDWARE_VERSION",          :address => [0x09, 0x10, 0x00]b,  :length => 4 },
        FIRMWARE_VERSION =>         { :name => "FIRMWARE_VERSION",          :address => [0x56, 0x1f, 0x01]b,  :length => 4 },
        BOOTLOADER_VERSION =>       { :name => "BOOTLOADER_VERSION",        :address => [0x56, 0x1f, 0x02]b,  :length => 4 },
        SERIAL_NUMBER =>            { :name => "SERIAL_NUMBER",             :address => [0x18, 0x10, 0x04]b,  :length => 4 },

        REVERSE_TRIGGER_MAPPING =>  { :name => "REVERSE_TRIGGER_MAPPING",   :address => [0x50, 0x25, 0x00]b,  :length => 1,   :values => [1, 2] },

        CURRENT_GEAR =>             { :name => "CURRENT_GEAR",              :address => [0x01, 0x61, 0x02]b,  :length => 1 },
        BATTERY_LEVEL =>            { :name => "BATTERY_LEVEL",             :address => [0x64, 0x61, 0x01]b,  :length => 2 },

        START_SELECT_GEAR =>        { :name => "START_SELECT_GEAR",         :address => [0x12, 0x25, 0x02]b,  :length => 1,   :minmax => [1, 12] },
        PRE_SELECT_CADENCE =>       { :name => "PRE_SELECT_CADENCE",        :address => [0x11, 0x25, 0x00]b,  :length => 1,   :minmax => [40, 100] },
        START_SELECT =>             { :name => "START_SELECT",              :address => [0x12, 0x25, 0x01]b,  :length => 1,   :values => [0, 1] },
        PRE_SELECT =>               { :name => "PRE_SELECT",                :address => [0x13, 0x25, 0x00]b,  :length => 1,   :values => [0, 1] },

        NUMBER_OF_GEARS =>          { :name => "NUMBER_OF_GEARS",           :address => [0x00, 0x25, 0x00]b,  :length => 1 },
    } as Lang.Dictionary<ParameterType, Lang.Dictionary>;

    function stringForParameter(parameter as ParameterType) as Lang.String
    {
        if(!PARAMETERS.hasKey(parameter))
        {
            return "UNKNOWN";
        }

        var parameterData = PARAMETERS[parameter] as Lang.Dictionary;
        return parameterData[:name] as Lang.String;
    }

    class UnknownParameterException extends Lang.Exception
    {
        private var _parameter as ParameterType;

        public function initialize(parameter as ParameterType)
        {
            Lang.Exception.initialize();
            _parameter = parameter;
        }

        public function getErrorMessage() as Lang.String?
        {
            return "Unknown Pinion Parameter " + _parameter;
        }
    }

    class ParameterNotWritableException extends Lang.Exception
    {
        private var _parameter as ParameterType;

        public function initialize(parameter as ParameterType)
        {
            Lang.Exception.initialize();
            _parameter = parameter;
        }

        public function getErrorMessage() as Lang.String?
        {
            return "Pinion Parameter " + _parameter + " is not writable";
        }
    }
}
