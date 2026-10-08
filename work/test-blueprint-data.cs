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

        string folder=Path.Combine(Directory.GetCurrentDirectory(),"work","blueprint-test-"+Guid.NewGuid().ToString("N"));
        try
        {
            var captured=Entry();BlueprintCapture.Set("My house",new List<BlueprintEntry>{captured});
            captured.X=50;captured.Sign="Changed after capture";
            string first=BlueprintCapture.Save(folder),second=BlueprintCapture.Save(folder);
            Check(File.Exists(first)&&File.Exists(second)&&first!=second,"Save did not create distinct files");
            Check(Path.GetFileName(second)=="My house (1).vbp","Duplicate save must get a numbered name");
            BlueprintData.SafeName(Path.GetFileNameWithoutExtension(second));
            using(var stream=File.OpenRead(first)){var saved=BlueprintData.Read(stream);Check(saved[0].X==1.25f&&saved[0].Sign!="Changed after capture","Saving reread mutable live capture data");}
            Check(Directory.GetFiles(folder,"*.tmp").Length==0,"Temporary save leaked");
            BlueprintCapture.Set(new string('A',48),new List<BlueprintEntry>{Entry()});
            BlueprintCapture.Save(folder);string longDuplicate=BlueprintCapture.Save(folder);
            BlueprintData.SafeName(Path.GetFileNameWithoutExtension(longDuplicate));
            BlueprintCapture.Clear();bool refused=false;
            try{BlueprintCapture.Save(folder);}catch(InvalidOperationException){refused=true;}
            Check(refused,"Save without capture must explain missing snapshot");
            Console.WriteLine("PASS: immutable capture, real file output/readback, numbered saves, valid duplicate names, cleanup and missing-capture error");
        }
        finally
        {
            BlueprintCapture.Clear();
            if(Directory.Exists(folder)){foreach(string file in Directory.GetFiles(folder))File.Delete(file);Directory.Delete(folder);}
        }
        Console.WriteLine("PASS: blueprint furniture/sign/transform persistence, safe names, malformed/oversized data and coordinate limits");
    }
}
