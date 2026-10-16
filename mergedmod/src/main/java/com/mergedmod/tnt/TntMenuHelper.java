package com.mergedmod.tnt;

import net.minecraft.core.component.DataComponents;
import net.minecraft.network.chat.Component;
import net.minecraft.world.Container;
import net.minecraft.world.SimpleContainer;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.component.ItemLore;

import java.util.List;

public class TntMenuHelper {
    public static Container createContainer() {
        Container container = new SimpleContainer(9);

        // Border panes
        ItemStack pane = new ItemStack(Items.GRAY_STAINED_GLASS_PANE);
        pane.set(DataComponents.CUSTOM_NAME, Component.literal(" "));

        for (int i = 0; i < 9; i++) {
            if (i != 4) {
                container.setItem(i, pane.copy());
            }
        }

        // Slot 4: Toggle item
        container.setItem(4, createTntToggleItem(TntSettings.isTntEnabled()));
        return container;
    }

    public static ItemStack createTntToggleItem(boolean enabled) {
        if (enabled) {
            ItemStack stack = new ItemStack(Items.REDSTONE_BLOCK);
            stack.set(DataComponents.CUSTOM_NAME, Component.literal("§c§lTNT Explosions: ENABLED"));
            stack.set(DataComponents.LORE, new ItemLore(List.of(
                Component.literal("§7Server Status: §cExplosions are ACTIVE"),
                Component.literal(""),
                Component.literal("§e▶ Click here to §4§lDISABLE §eTNT explosions!")
            )));
            return stack;
        } else {
            ItemStack stack = new ItemStack(Items.BARRIER);
            stack.set(DataComponents.CUSTOM_NAME, Component.literal("§a§lTNT Explosions: DISABLED"));
            stack.set(DataComponents.LORE, new ItemLore(List.of(
                Component.literal("§7Server Status: §aExplosions are BLOCKED"),
                Component.literal(""),
                Component.literal("§e▶ Click here to §a§lENABLE §eTNT explosions!")
            )));
            return stack;
        }
    }
}
