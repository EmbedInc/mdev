--------------- FILE FOR C#: -- call it <name>_ids.cs
---- NOTE: Most of this is static, template, text. Only a few lines are variable.
----       The comma after the second "new Tuple<>" line is not a typo. C# allows
----       the trailing comma to make programmatic code generation easier. The
----       123 in the public override int FirmwareId line should be the id of the
----       firmware. If this is difficult to get, then just leave the line out.

using System;
using System.Linq;

namespace Jowa.MdevIds
{
    class IDs_<name> : IDs_Base
    {
        // Simple constants
        public const int CFG_jcan = 1;
        public const int CFG_cantest = 2;

        // List of names and corresponding ids
        private static readonly Tuple<string, int>[] _ids = new Tuple<string, int>[]
        {
            new Tuple<string, int>("jcan", CFG_jcan),
            new Tuple<string, int>("cantest", CFG_cantest),
        };

        // Get the name and id of this firmware
        public override string FirmwareName => "<name>";
        public override int FirmwareId => 123;

        // Get a module Id given a name
        public override int GetModuleId(string s)
            => (from u in _ids where u.Item1 == s select u.Item2).FirstOrDefault();

        // Get a module Name given an ID
        public override string GetModuleName(int n)
            => (from u in _ids where u.Item2 == n select u.Item1).FirstOrDefault();

        // Get the number of modules defined
        public override int ModuleCount => _ids.Length;

        // Get the ID and name of the Nth module
        public override Tuple<string, int> GetModuleEntry(int n)
                => new Tuple<string, int>(_ids[n].Item1, _ids[n].Item2);
    }
}
