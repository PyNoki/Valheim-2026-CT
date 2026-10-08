using System;
using System.Reflection;
using ValheimSoloToolkit;
namespace UnityEngine {
    public class Object { public static implicit operator bool(Object x) { return x != null; } public static void Destroy(Object x) {} }
    public class GameObject : Object { public GameObject(string name) {} public T AddComponent<T>() where T:new() { return new T(); } }
    public class MonoBehaviour : Object { public GameObject gameObject = new GameObject("test"); }
    public class Animator : Object { public float speed=1.25f; }
}
public class Skills { public enum SkillType { Swords, Pickaxes } }
public class ItemDrop { public class ItemData { public class SharedData { public Skills.SkillType m_skillType; } public SharedData m_shared=new SharedData(); public float m_durability=2; public float GetMaxDurability() { return 150; } } }
public class Player : UnityEngine.Object {
    public static Player m_localPlayer;
    public float m_stamina=3, max=120;
    public bool dead, attacking;
    public ItemDrop.ItemData weapon;
    public UnityEngine.Animator animator=new UnityEngine.Animator();
    public bool IsDead() { return dead; } public bool InAttack() { return attacking; }
    public ItemDrop.ItemData GetCurrentWeapon() { return weapon; }
    public float GetMaxStamina() { return max; }
    public T GetComponentInChildren<T>() where T:class { return animator as T; }
}
class Test {
    static void Check(bool value) { if (!value) throw new Exception("Miner assertion failed"); }
    static void Call(object obj,string method) { obj.GetType().GetMethod(method,BindingFlags.NonPublic|BindingFlags.Instance).Invoke(obj,null); }
    static void Main() {
        var p=new Player(); Player.m_localPlayer=p; RapidMinerV1.Configure(p);
        var d=new RapidMinerDriverV1();d.Owner=p;
        p.weapon=new ItemDrop.ItemData();d.Protect();Check(p.m_stamina==3 && p.weapon.m_durability==2);
        p.weapon.m_shared.m_skillType=Skills.SkillType.Pickaxes;
        d.Protect();Check(p.m_stamina==120 && p.weapon.m_durability==150);
        p.max=180;d.Protect();Check(p.m_stamina==180);
        p.attacking=true;Call(d,"LateUpdate");Check(p.animator.speed==10);
        Call(d,"LateUpdate");p.weapon=new ItemDrop.ItemData();Call(d,"LateUpdate");Check(p.animator.speed==1.25f && p.weapon.m_durability==2);
        p.weapon.m_shared.m_skillType=Skills.SkillType.Pickaxes;Call(d,"LateUpdate");
        RapidMinerV1.Disable();Call(d,"Update");Check(p.animator.speed==1.25f);
        p.m_stamina=7;d.Protect();Check(p.m_stamina==7);
        RapidMinerV1.Configure(p);Call(d,"LateUpdate");Player.m_localPlayer=new Player();Call(d,"LateUpdate");Check(p.animator.speed==1.25f);
        p.m_stamina=9;d.Protect();Check(p.m_stamina==9);
        Player.m_localPlayer=p;p.dead=true;d.Protect();Check(p.m_stamina==9);
        Console.WriteLine("PASS: pickaxe-only refill, dynamic stamina, 10x animation, tool switch, disable, world change and dead-player guards");
    }
}
