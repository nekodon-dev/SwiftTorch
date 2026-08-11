package com.nekodon.swifttorch;

import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.event.player.UseBlockCallback;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.sounds.SoundSource;
import net.minecraft.tags.ItemTags;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.InteractionResult;
import net.minecraft.world.entity.player.Inventory;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.BlockItem;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.item.context.BlockPlaceContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.SoundType;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.BlockHitResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SwiftTorch implements ModInitializer {

    public static final String MOD_ID = "swifttorch";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    @Override
    public void onInitialize() {
        LOGGER.info("SwiftTorch mod has been initialized!");
        UseBlockCallback.EVENT.register(this::onBlockRightClick);
    }

    private InteractionResult onBlockRightClick(
            Player player,
            Level level,
            InteractionHand hand,
            BlockHitResult hitResult
    ) {
        if (level.isClientSide() || hand != InteractionHand.MAIN_HAND) {
            return InteractionResult.PASS;
        }

        // Sneaking keeps the vanilla interaction available to the player.
        if (player.isShiftKeyDown()) {
            return InteractionResult.PASS;
        }

        ItemStack toolStack = player.getItemInHand(InteractionHand.MAIN_HAND);
        if (!toolStack.getItem().builtInRegistryHolder().is(ItemTags.PICKAXES)) {
            return InteractionResult.PASS;
        }

        Inventory inventory = player.getInventory();
        int torchSlot = findTorchInInventory(inventory);
        if (torchSlot == Inventory.NOT_FOUND_INDEX) {
            return InteractionResult.PASS;
        }

        BlockState clickedState = level.getBlockState(hitResult.getBlockPos());
        InteractionResult itemResult = clickedState.useItemOn(toolStack, level, player, hand, hitResult);

        if (itemResult == InteractionResult.TRY_WITH_EMPTY_HAND) {
            InteractionResult blockResult = clickedState.useWithoutItem(level, player, hitResult);
            if (blockResult != InteractionResult.PASS) {
                return blockResult;
            }
        } else if (itemResult != InteractionResult.PASS) {
            return itemResult;
        }

        ItemStack torchStack = inventory.getItem(torchSlot);
        BlockPlaceContext placementContext = new BlockPlaceContext(player, hand, torchStack, hitResult);
        InteractionResult placementResult = ((BlockItem) Items.TORCH).place(placementContext);

        if (placementResult.consumesAction()) {
            player.swing(hand, true);

            BlockState placedState = level.getBlockState(placementContext.getClickedPos());
            SoundType soundType = placedState.getSoundType();
            SoundEvent placeSound = soundType.getPlaceSound();
            level.playSound(
                    null,
                    placementContext.getClickedPos(),
                    placeSound,
                    SoundSource.BLOCKS,
                    (soundType.getVolume() + 1.0F) / 2.0F,
                    soundType.getPitch() * 0.8F
            );
        }

        return placementResult;
    }

    private int findTorchInInventory(Inventory inventory) {
        for (int slot = 0; slot < inventory.getContainerSize(); slot++) {
            ItemStack stack = inventory.getItem(slot);
            if (!stack.isEmpty() && stack.getItem() == Items.TORCH) {
                return slot;
            }
        }

        return Inventory.NOT_FOUND_INDEX;
    }
}
