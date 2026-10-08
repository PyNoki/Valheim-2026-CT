using System;
using System.IO;
using System.Collections.Generic;
using ValheimSoloToolkit;
class BlueprintDataTest
{
    static void Check(bool b,string s){if(!b)throw new Exception(s);}
    static void Reject(Action a,string s){try{a();}catch(InvalidDataException){return;}throw new Exception(s);}
    static BlueprintEntry Entry(){return new BlueprintEntry{Prefab="sign",Sign="Home\nViking \u2694",X=1.25f,Y=-.1f,Z=2.5f,QW=1};}
    static void Main()
    {
        var data=new List<BlueprintEntry>{Entry(),new BlueprintEntry{Prefab="piece_chest_wood",QY=1}};
        using(var stream=new MemoryStream())
        {
            BlueprintData.Write(stream,data);stream.Position=0;var copy=BlueprintData.Read(stream);
            Check(copy.Count==2&&copy[0].Sign==data[0].Sign&&copy[0].X==1.25f&&copy[1].QY==1,"Furnishings, unicode sign text or transform lost on round trip");
            stream.Position=stream.Length;stream.WriteByte(42);stream.Position=0;Reject(()=>BlueprintData.Read(stream),"Trailing data accepted");
        }
        Reject(()=>BlueprintData.SafeName("../Other"),"Path traversal accepted");
        Reject(()=>BlueprintData.SafeName(" "),"Empty name accepted");
        Check(BlueprintData.SafeName(" Home 2 ")=="Home 2","Valid name altered");
        var bad=Entry();bad.X=Single.NaN;Reject(()=>BlueprintData.Validate(new List<BlueprintEntry>{bad}),"NaN accepted");
        bad=Entry();bad.QW=0;Reject(()=>BlueprintData.Validate(new List<BlueprintEntry>{bad}),"Invalid rotation accepted");
        bad=Entry();bad.Z=101;Reject(()=>BlueprintData.Validate(new List<BlueprintEntry>{bad}),"Out-of-bounds position accepted");
        var many=new List<BlueprintEntry>();for(int i=0;i<513;i++)many.Add(Entry());Reject(()=>BlueprintData.Validate(many),"Oversized blueprint accepted");
        using(var stream=new MemoryStream())
        {using(var w=new BinaryWriter(stream,System.Text.Encoding.UTF8,true)){w.Write("STBP1");w.Write(Int32.MaxValue);}stream.Position=0;Reject(()=>BlueprintData.Read(stream),"Hostile piece count accepted");}
        using(var stream=new MemoryStream(new byte[2*1024*1024+1]))Reject(()=>BlueprintData.Read(stream),"Oversized file accepted");
        Console.WriteLine("PASS: blueprint furniture/sign/transform persistence, safe names, malformed/oversized data and coordinate limits");
    }
}
