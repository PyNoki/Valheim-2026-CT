using System;
using System.IO;
using System.Collections.Generic;
namespace ValheimSoloToolkit
{
    public sealed class BlueprintEntry
    {
        public string Prefab,Sign="";
        public float X,Y,Z,QX,QY,QZ,QW;
    }
    public static class BlueprintData
    {
        public const int Limit=512;
        public static string SafeName(string name)
        {
            if(String.IsNullOrWhiteSpace(name)||name.Length>48)throw new InvalidDataException("Use a blueprint name of 1-48 letters, numbers, spaces, hyphens, underscores or parentheses.");
            foreach(char c in name)if(!Char.IsLetterOrDigit(c)&&c!=' '&&c!='-'&&c!='_'&&c!='('&&c!=')')throw new InvalidDataException("Blueprint name contains an invalid character.");
            return name.Trim();
        }
        private static bool Finite(float f){return !Single.IsNaN(f)&&!Single.IsInfinity(f);}
        public static void Validate(List<BlueprintEntry> entries)
        {
            if(entries.Count<1||entries.Count>Limit)throw new InvalidDataException("Blueprint must contain 1-512 pieces.");
            foreach(var e in entries)
            {
                if(String.IsNullOrEmpty(e.Prefab)||e.Prefab.Length>128||e.Sign==null||e.Sign.Length>1024)throw new InvalidDataException("Invalid blueprint text.");
                foreach(float f in new[]{e.X,e.Y,e.Z,e.QX,e.QY,e.QZ,e.QW})if(!Finite(f))throw new InvalidDataException("Invalid blueprint coordinates.");
                if(Math.Abs(e.X)>100||Math.Abs(e.Y)>100||Math.Abs(e.Z)>100)throw new InvalidDataException("Blueprint exceeds 100m bounds.");
                float norm=e.QX*e.QX+e.QY*e.QY+e.QZ*e.QZ+e.QW*e.QW;
                if(Math.Abs(norm-1)>0.01f)throw new InvalidDataException("Invalid blueprint rotation.");
            }
        }
        public static void Write(Stream stream,List<BlueprintEntry> entries)
        {
            Validate(entries);
            using(var w=new BinaryWriter(stream,System.Text.Encoding.UTF8,true))
            {
                w.Write("STBP1");w.Write(entries.Count);
                foreach(var e in entries){w.Write(e.Prefab);w.Write(e.Sign);foreach(float f in new[]{e.X,e.Y,e.Z,e.QX,e.QY,e.QZ,e.QW})w.Write(f);}
            }
        }
        public static List<BlueprintEntry> Read(Stream stream)
        {
            if(stream.Length>2*1024*1024)throw new InvalidDataException("Blueprint file too large.");
            var entries=new List<BlueprintEntry>();
            using(var r=new BinaryReader(stream,System.Text.Encoding.UTF8,true))
            {
                if(r.ReadString()!="STBP1")throw new InvalidDataException("Unsupported blueprint format.");
                int n=r.ReadInt32();if(n<1||n>Limit)throw new InvalidDataException("Invalid piece count.");
                for(int i=0;i<n;i++)entries.Add(new BlueprintEntry{Prefab=r.ReadString(),Sign=r.ReadString(),X=r.ReadSingle(),Y=r.ReadSingle(),Z=r.ReadSingle(),QX=r.ReadSingle(),QY=r.ReadSingle(),QZ=r.ReadSingle(),QW=r.ReadSingle()});
                if(stream.Position!=stream.Length)throw new InvalidDataException("Unexpected blueprint data.");
            }
            Validate(entries);return entries;
        }
    }
}
