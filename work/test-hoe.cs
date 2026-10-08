using System;
using System.Reflection;
using ValheimSoloToolkit;
namespace UnityEngine {
    public class Object { public static implicit operator bool(Object x) { return x != null; } public static void Destroy(Object x) {} }
    public class GameObject : Object { public GameObject(string name) {} public T AddComponent<T>() where T:new() { return new T(); } }
    public class MonoBehaviour : Object { public GameObject gameObject = new GameObject("test"); }
    public static class Time { public static float time = 10; }
}
public class ItemDrop { public class ItemData { public class SharedData { public string m_name; } public SharedData m_shared=new SharedData(); public float m_durability=2; public float GetMaxDurability() { return 150; } } }
public class Humanoid : UnityEngine.Object {
    public ItemDrop.ItemData weapon;
    private ItemDrop.ItemData GetRightItem() { return weapon; }
}
public class Player : Humanoid {
    public static Player m_localPlayer;
    public float m_stamina=3, max=120, m_placeDelay=0.4f, m_placePressedTime=-9999, m_lastToolUseTime;
    public bool dead, placing=true;
    public bool IsDead() { return dead; } public bool InPlaceMode() { return placing; }
    public float GetMaxStamina() { return max; }
}
public static class Hud { public static bool selection, radial; public static bool IsPieceSelectionVisible() { return selection; } public static bool InRadial() { return radial; } }
public static class ZInput { public static bool attack, place, alt; public static bool GetButton(string name) { return name=="Attack" ? attack : name=="JoyPlace" ? place : alt; } }
class Test {
    static void Check(bool value, string message) { if (!value) throw new Exception(message); }
    static void Call(object obj,string method) { obj.GetType().GetMethod(method,BindingFlags.NonPublic|BindingFlags.Instance).Invoke(obj,null); }
    static void Main() {
        var p=new Player(); Player.m_localPlayer=p; RapidHoeV1.Configure(p);
        var d=new RapidHoeDriverV1(); d.Owner=p;
        p.weapon=new ItemDrop.ItemData();p.weapon.m_shared.m_name="$item_hammer";
        ZInput.attack=true;d.Step(true);Check(p.m_placeDelay==0.4f && p.m_stamina==3 && p.weapon.m_durability==2,"Hammer changed");
        p.weapon.m_shared.m_name="$item_hoe";d.Step(true);
        Check(p.m_placeDelay==0.05f && p.m_stamina==120 && p.weapon.m_durability==150 && p.m_placePressedTime==10,"Hoe not accelerated/protected");
        p.max=180;p.m_lastToolUseTime=10;p.m_placePressedTime=-9999;
        UnityEngine.Time.time=10.01f;d.Step(true);Check(p.m_placePressedTime==-9999 && p.m_stamina==180,"Cooldown/dynamic stamina");
        UnityEngine.Time.time=10.1f;ZInput.attack=false;d.Step(true);Check(p.m_placePressedTime==-9999,"Release repeated an action");
        ZInput.place=true;d.Step(true);Check(p.m_placePressedTime==10.1f,"Controller repeat failed");
        p.m_placePressedTime=-9999;ZInput.alt=true;d.Step(true);Check(p.m_placePressedTime==-9999,"Controller alt generated terrain action");ZInput.alt=false;
        d.Step(false);Check(p.m_placeDelay==0.4f && p.m_placePressedTime==-9999,"Input disabled failed to restore");
        Hud.selection=true;d.Step(true);Check(p.m_placeDelay==0.4f && p.m_placePressedTime==-9999,"Piece menu allowed repeat");Hud.selection=false;
        Hud.radial=true;d.Step(true);Check(p.m_placeDelay==0.4f,"Radial menu allowed repeat");Hud.radial=false;
        d.Step(true);p.weapon.m_shared.m_name="$item_pickaxe_iron";d.Step(true);Check(p.m_placeDelay==0.4f,"Tool switch did not restore");
        p.weapon.m_shared.m_name="$item_hoe";d.Step(true);RapidHoeV1.Disable();Call(d,"Update");Check(p.m_placeDelay==0.4f,"Disable did not restore");
        p.m_stamina=7;d.Step(true);Check(p.m_stamina==7,"Disabled stamina write");
        RapidHoeV1.Configure(p);d.Step(true);Player.m_localPlayer=new Player();Call(d,"Update");Check(p.m_placeDelay==0.4f,"World change did not restore");
        Player.m_localPlayer=p;p.dead=true;p.m_stamina=8;d.Step(true);Check(p.m_stamina==8,"Dead player write");
        p.dead=false;p.placing=false;d.Step(true);Check(p.m_placeDelay==0.4f,"Non-placement mode changed");
        Console.WriteLine("PASS: hoe-only repeat, cooldown, mouse/controller release, input/menu guards, stamina/durability, tool switch, disable and world unload");
    }
}
