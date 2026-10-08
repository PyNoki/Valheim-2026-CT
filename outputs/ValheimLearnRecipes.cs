using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

namespace ValheimSoloToolkit
{
    public static class LearnRecipesV1
    {
        public static int Enabled;
        public static string Status;
        private static Player owner;
        private const BindingFlags Flags=BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic;
        public static void Configure(Player player){owner=player;Status="Queued recipe grant. Return to the game and unpause.";Enabled=1;}
        public static void Disable(){Enabled=0;owner=null;}
        public static void Tick(Player player)
        {
            if(Enabled!=1)return;
            if(!owner||owner!=Player.m_localPlayer){Disable();Status="Recipe grant cancelled: character changed.";return;}
            if(player!=owner)return;
            Enabled=0; // One-shot, including failures.
            try
            {
                if(player.IsDead()||player.IsTeleporting())throw new InvalidOperationException("Wait until alive and finished teleporting, then retry.");
                if(!ObjectDB.instance)throw new InvalidOperationException("Item database unavailable.");
                var field=typeof(Player).GetField("m_knownRecipes",Flags);
                var refresh=typeof(Player).GetMethod("UpdateAvailablePiecesList",Flags);
                if(field==null||refresh==null)throw new MissingMemberException("Recipe metadata unavailable.");
                var known=field.GetValue(player) as HashSet<string>;
                if(known==null)throw new InvalidOperationException("Known recipe storage unavailable.");
                var names=new HashSet<string>();
                foreach(var recipe in ObjectDB.instance.m_recipes)
                    if(recipe&&recipe.m_enabled&&recipe.m_item&&recipe.m_item.m_itemData!=null)
                        Add(names,recipe.m_item.m_itemData.m_shared.m_name);
                foreach(var prefab in ObjectDB.instance.m_items)
                {
                    var item=prefab?prefab.GetComponent<ItemDrop>():null;
                    var table=item&&item.m_itemData!=null?item.m_itemData.m_shared.m_buildPieces:null;
                    if(!table)continue;
                    foreach(var obj in table.m_pieces)
                    {
                        var piece=obj?obj.GetComponent<Piece>():null;
                        if(piece&&piece.m_enabled)Add(names,piece.m_name);
                    }
                }
                int added=0;
                foreach(var name in names)if(known.Add(name))added++;
                refresh.Invoke(player,null);
                Status="Learned "+added+" new crafting/building recipes ("+names.Count+" available). Reopen crafting/build menus. Saved with your character; normal materials and stations still apply.";
            }
            catch(Exception e){Status="Recipe grant stopped: "+e.GetBaseException().Message;}
            finally{owner=null;}
        }
        private static void Add(HashSet<string> names,string name){if(!string.IsNullOrEmpty(name))names.Add(name);}
    }
}
