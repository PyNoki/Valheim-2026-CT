from pathlib import Path
import subprocess
import ctypes

compiler = r'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
s = Path('work/test-death-recovery.cs').read_text().replace('DeathRecoveryV2', 'RecoverySpawnBetaV3')
s = s.replace('public class ZNet:UnityEngine.Object {', '''public struct ZDOID {
 public ushort UserKey {private get;set;} public uint ID {get;set;} public long UserID {get{return 22;}}
 public ZDOID(ushort key,uint id):this(){UserKey=key;ID=id;}
 public static bool operator ==(ZDOID a,ZDOID b){return a.UserKey==b.UserKey && a.ID==b.ID;}
 public static bool operator !=(ZDOID a,ZDOID b){return !(a==b);}
 public override bool Equals(object o){return o is ZDOID && this==(ZDOID)o;} public override int GetHashCode(){return (int)ID;}
}
public class ZRoutedRpc {
 public static ZRoutedRpc instance=new ZRoutedRpc(); public int sent; public long owner; public Vector3 point; public ZDOID target;
 public void InvokeRoutedRPC(long recipient,ZDOID id,string method,params object[] args){if(method!="RPC_TeleportTo"||args.Length!=3||!(bool)args[2])throw new Exception("wrong RPC");sent++;owner=recipient;target=id;point=(Vector3)args[0];}
}
public class ZNet:UnityEngine.Object {
 public struct PlayerInfo {public string m_name;public ZDOID m_characterID;}
 public bool admin=true; public ZDOID LocalPlayerCharacterID {get{return new ZDOID(1,1);}}
 public List<PlayerInfo> roster=new List<PlayerInfo>(); public List<PlayerInfo> GetPlayerList(){return roster;}
 public bool LocalPlayerIsAdminOrHost(){return admin;}
''')
s = s.replace('public class ZDOMan {', 'public class ZDOMan { public ZDO remote; public ZDO GetZDO(ZDOID id){return remote;}')
s = s.replace('static void Main(){', '''static void Main(){
  Reset();ZRoutedRpc.instance=new ZRoutedRpc();ZNet.instance.server=false;
  ZNet.instance.roster.Add(new ZNet.PlayerInfo{m_name="Friend",m_characterID=new ZDOID(2,7)});
  RecoverySpawnBetaV3.QueueSummon(p,"020007000000","0100000000000000");Check(ZRoutedRpc.instance.sent==0,"no RPC before tick");
  RecoverySpawnBetaV3.Tick(p);Check(RecoverySpawnBetaV3.GetState()==3 && ZRoutedRpc.instance.sent==1 && ZRoutedRpc.instance.owner==22 && ZRoutedRpc.instance.point.x==3,"distant remote summon uses identity and safe landing");
  RecoverySpawnBetaV3.Tick(p);Check(ZRoutedRpc.instance.sent==1,"one summon per request");
  Reset();ZNet.instance.admin=false;RecoverySpawnBetaV3.QueueSummon(p,"020007000000","0100000000000000");RecoverySpawnBetaV3.Tick(p);Failed("permission");
  Reset();RecoverySpawnBetaV3.QueueSummon(p,"020007000000","0100000000000000");RecoverySpawnBetaV3.Tick(p);Failed("disconnected");
  Reset();ZNet.instance.roster.Add(new ZNet.PlayerInfo{m_name="Friend",m_characterID=new ZDOID(2,7)});ZDOMan.instance.remote=new ZDO{networkOwner=99};
  RecoverySpawnBetaV3.QueueSummon(p,"020007000000","0100000000000000");RecoverySpawnBetaV3.Tick(p);Check(ZRoutedRpc.instance.owner==99 && ZRoutedRpc.instance.sent==2,"current owner wins over creator");
  Reset();ZNet.instance.roster.Add(new ZNet.PlayerInfo{m_name="Friend",m_characterID=new ZDOID(2,7)});Physics.ground=false;
  RecoverySpawnBetaV3.QueueSummon(p,"020007000000","0100000000000000");RecoverySpawnBetaV3.Tick(p);Failed("No clear landing");Check(ZRoutedRpc.instance.sent==2,"no unsafe RPC");
  Reset();RecoverySpawnBetaV3.QueueSummon(p,"020007000000","0100000000000000");RecoverySpawnBetaV3.Cancel();RecoverySpawnBetaV3.Tick(p);Check(ZRoutedRpc.instance.sent==2,"cancelled summon never sent");
  Console.WriteLine("PASS: remote admin summon RPC, identity routing, current owner, one-shot send, admin/disconnect/landing guards and cancellation.");
''')
s = s.replace('public class Object {', '''public class Object {
 public static int spawns; public static Vector3 last;
 public static GameObject Instantiate(GameObject prefab, Vector3 position, Quaternion rotation) { spawns++;last=position;return new GameObject(); }
''')
s = s.replace('return container as T;', 'return (typeof(T)==typeof(Pickable)?(object)new Pickable():typeof(T)==typeof(ZNetView)?(object)new ZNetView():container) as T;')
s = s.replace('public struct Quaternion {', 'public struct Quaternion { public static Quaternion identity {get{return new Quaternion();}}')
s = s.replace('public class ZNetScene {', 'public class Pickable:Component {} public class ZNetView:Component {}\npublic class ZNetScene:UnityEngine.Object { public bool missing; public GameObject GetPrefab(string name){if(name!="BlueberryBush")throw new Exception("Wrong prefab");return missing?null:new GameObject();}')
s = s.replace('static void Main(){', '''static void Main(){
  Reset();UnityEngine.Object.spawns=0;p.transform.position=new Vector3(12,4,56);
  RecoverySpawnBetaV2.Queue(p,4,"0100000000000000");Check(UnityEngine.Object.spawns==0,"queue does not invoke Unity");
  RecoverySpawnBetaV2.Tick(p);Check(UnityEngine.Object.spawns==1 && UnityEngine.Object.last.x==12 && UnityEngine.Object.last.y==4 && UnityEngine.Object.last.z==56,"spawn at feet");
  RecoverySpawnBetaV2.Tick(p);Check(UnityEngine.Object.spawns==1,"no repeat spawn");
  Reset();ZNet.instance.server=false;p.transform.position=new Vector3(20,5,30);Run(4);Check(RecoverySpawnBetaV2.GetState()==3 && UnityEngine.Object.spawns==2 && UnityEngine.Object.last.x==20,"remote client spawns at own feet");RecoverySpawnBetaV2.Tick(p);Check(UnityEngine.Object.spawns==2,"remote client does not repeat spawn");
  Reset();ZNetScene.instance.missing=true;Run(4);Failed("prefab unavailable");
  Reset();p.dead=true;Run(4);Failed("died");
  Reset();ZNet.instance.world=2;Run(4);Failed("changed");
  Reset();p.teleporting=true;Run(4);Failed("teleport");
  Reset();p.transform.position.x=float.NaN;Run(4);Failed("invalid");
  Reset();RecoverySpawnBetaV2.Queue(p,4,"0100000000000000");RecoverySpawnBetaV2.Cancel();RecoverySpawnBetaV2.Tick(p);
  Check(UnityEngine.Object.spawns==2,"cancel and rejected requests never spawn");
  Console.WriteLine("PASS: spawn queued on game thread, exact feet position, one-shot execution, remote client success and prefab/death/world/teleport/position guards and cancellation.");
''')
s = s.replace('RecoverySpawnBetaV2', 'RecoverySpawnBetaV3')
s = s.replace('RecoverySpawnBetaV3', 'RecoverySpawnBetaV11')
s += '''
public class Inventory {}
public class Humanoid {}
public class ItemDrop { public class ItemData {} }
namespace ValheimSoloToolkit { public static class ReplenishV1 {
 public static Inventory Prepare(Inventory t,Inventory s,ItemDrop.ItemData i){return null;}
 public static ItemDrop.ItemData Copy(){return null;}
 public static int Drop(Humanoid a,Inventory s,ItemDrop.ItemData i,int n){return -1;}
} }
namespace ValheimSoloToolkit { public static class BoatFunV4 {
 public static int toggles; public static string Status="Off";
 public static void Stop(){Status="Off";} public static void Toggle(Player p){toggles++;Status="On";}
} }
'''
s = s.replace('static void Main(){', '''static void Main(){
  Reset();RecoverySpawnBetaV11.Queue(p,6,"0100000000000000");Check(BoatFunV4.toggles==0,"boat queue waits for game thread");
  RecoverySpawnBetaV11.Tick(p);RecoverySpawnBetaV11.Tick(p);Check(BoatFunV4.toggles==1,"one boat toggle per request");
  Reset();RecoverySpawnBetaV11.Queue(p,6,"0100000000000000");RecoverySpawnBetaV11.Cancel();RecoverySpawnBetaV11.Tick(p);Check(BoatFunV4.toggles==1,"cancelled boat toggle not executed");
  Console.WriteLine("PASS: boat activation queued on game thread, one-shot toggle and cancellation.");
''')
s = s.replace('public long GetLong(int key,long fallback)', 'public long GetOwner(){return networkOwner;} public long GetLong(int key,long fallback)')
Path('work/test-beta.generated.cs').write_text(s)
subprocess.run([compiler, '/nologo', '/out:' + str(Path('work/test-beta.exe').resolve()), str(Path('outputs/ValheimRecoverySpawnBeta.cs').resolve()), str(Path('work/test-beta.generated.cs').resolve())], check=True)
subprocess.run([str(Path('work/test-beta.exe').resolve())], check=True)
Path('work/test-beta.generated.cs').unlink()

lua = ctypes.CDLL(r'C:\Program Files\Cheat Engine\lua53-64.dll')
lua.luaL_newstate.restype=ctypes.c_void_p
lua.luaL_loadfilex.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_char_p]
lua.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p]
lua.lua_tolstring.restype=ctypes.c_char_p
state=lua.luaL_newstate()
result=lua.luaL_loadfilex(state,b'outputs/ValheimBeta.lua',None)
assert result==0, lua.lua_tolstring(state,-1,None)
print('Beta Lua syntax verified by Cheat Engine Lua 5.3.')
