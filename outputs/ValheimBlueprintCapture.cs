using System;
using System.IO;
using System.Collections.Generic;
namespace ValheimSoloToolkit
{
    // Immutable serialized capture: saving from CE never reads live Unity objects.
    internal static class BlueprintCapture
    {
        private static readonly object gate=new object();
        private static byte[] snapshot;
        private static string name;
        internal static void Clear(){lock(gate){snapshot=null;name=null;}}
        internal static void Set(string captureName,List<BlueprintEntry> entries)
        {
            captureName=BlueprintData.SafeName(captureName);
            using(var stream=new MemoryStream())
            {
                BlueprintData.Write(stream,entries);
                lock(gate){name=captureName;snapshot=stream.ToArray();}
            }
        }
        internal static string Save(string folder)
        {
            lock(gate)
            {
                if(snapshot==null)throw new InvalidOperationException("No captured selection is ready. Click Capture, return to the game once, and wait for the captured piece count.");
                Directory.CreateDirectory(folder);
                string temporary=Path.Combine(folder,Guid.NewGuid().ToString("N")+".tmp");
                try
                {
                    File.WriteAllBytes(temporary,snapshot);
                    // Verify persisted data before publishing a discoverable .vbp file.
                    using(var stream=File.OpenRead(temporary))BlueprintData.Read(stream);
                    for(int suffix=0;suffix<10000;suffix++)
                    {
                        string tag=suffix==0?"":" ("+suffix+")";
                        string path=Path.Combine(folder,name.Substring(0,Math.Min(name.Length,48-tag.Length))+tag+".vbp");
                        if(File.Exists(path))continue;
                        try{File.Move(temporary,path);return path;}
                        catch(IOException){if(!File.Exists(path))throw;}
                    }
                    throw new IOException("Too many blueprints with this name. Capture with a new name.");
                }
                finally{if(File.Exists(temporary))File.Delete(temporary);}
            }
        }
    }
}
