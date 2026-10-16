package com.mergedmod.tnt;

import net.minecraft.network.chat.Component;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.world.Container;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.inventory.ChestMenu;
import net.minecraft.world.inventory.ClickType;
import net.minecraft.world.inventory.MenuType;
import net.minecraft.world.item.ItemStack;

public class TntMenu extends ChestMenu {
    public TntMenu(int syncId, Inventory playerInventory, Container container) {
        super(MenuType.GENERIC_9x1, syncId, playerInventory, container, 1);
    }

    @Override
    public void clicked(int slotIndex, int button, ClickType clickType, Player player) {
        if (slotIndex >= 0 && slotIndex < 9) {
            if (slotIndex == 4) {
                boolean newState = !TntSettings.isTntEnabled();
                TntSettings.setTntEnabled(newState);

                // Update slot 4 item in container
                getContainer().setItem(4, TntMenuHelper.createTntToggleItem(newState));
                broadcastChanges();

                if (player instanceof ServerPlayer sp) {
                    sp.playSound(SoundEvents.UI_BUTTON_CLICK.value(), 1.0f, 1.0f);
                    sp.sendSystemMessage(Component.literal("§6[TNT Control] §7TNT Explosions are now: " + (newState ? "§c§lENABLED" : "§a§lDISABLED")));
                }
            }
            // Prevent picking up or moving GUI items
            return;
        }
        super.clicked(slotIndex, button, clickType, player);
    }

    @Override
    public ItemStack quickMoveStack(Player player, int slotIndex) {
        return ItemStack.EMPTY;
    }
}
