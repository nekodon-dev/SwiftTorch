package com.nekodon.swifttorch;

import net.fabricmc.api.ModInitializer;
import net.fabricmc.fabric.api.event.player.UseBlockCallback;
import net.minecraft.block.BlockState;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.entity.player.PlayerInventory;
import net.minecraft.item.BlockItem;
import net.minecraft.item.ItemPlacementContext;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Items;
import net.minecraft.registry.tag.ItemTags;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvent;
import net.minecraft.util.ActionResult;
import net.minecraft.util.Hand;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.world.World;
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

    /**
     * ブロックが右クリックされた時に呼び出されるメソッド（修正済み）
     */
    private ActionResult onBlockRightClick(PlayerEntity player, World world, Hand hand, BlockHitResult hitResult) {

        // サーバー側、かつメインハンドでのみ実行
        if (world.isClient() || hand != Hand.MAIN_HAND) {
            return ActionResult.PASS;
        }

        // スニーク中はMODの機能を完全にオフにする（バニラの「チェストにブロックを置く」動作などを優先）
        if (player.isSneaking()) {
            return ActionResult.PASS;
        }

        // メインハンドがツルハシかチェック
        ItemStack mainHandStack = player.getStackInHand(Hand.MAIN_HAND);
        if (!mainHandStack.isIn(ItemTags.PICKAXES)) {
            return ActionResult.PASS;
        }

        // インベントリにトーチがあるかチェック
        int torchSlot = findTorchInInventory(player.getInventory());
        if (torchSlot == -1) {
            return ActionResult.PASS;
        }

        BlockState clickedBlockState = world.getBlockState(hitResult.getBlockPos());

        // --- 【1.21.4専用：チェストやギミックの判定】 ---

        // 1. アイテム（ツルハシ）を持ってブロックを触った時の判定
        // 最新の1.21.4では、ここも ActionResult を返します
        ActionResult itemResult = clickedBlockState.onUseWithItem(player.getStackInHand(hand), world, player, hand, hitResult);
        if (itemResult.isAccepted()) {
            return itemResult; // そのまま結果を返す
        }

        // 2. ブロック自体の機能（チェスト、ドアなど）の判定
        // 引数が3つの onUse メソッドを使います
        ActionResult blockResult = clickedBlockState.onUse(world, player, hitResult);
        if (blockResult.isAccepted()) {
            return blockResult;
        }

        // --- ここまでで何も発動しなかった場合（ただの石など）、トーチを設置する ---

        ItemStack torchStack = player.getInventory().getStack(torchSlot);
        ItemPlacementContext placementContext = new ItemPlacementContext(player, hand, torchStack, hitResult);

        // トーチを設置
        ActionResult placeResult = ((BlockItem) Items.TORCH).place(placementContext);

        if (placeResult.isAccepted()) {
            // 腕振りの実行
            player.swingHand(hand, true);

            // 音の再生
            BlockState placedState = world.getBlockState(placementContext.getBlockPos());
            SoundEvent sound = placedState.getSoundGroup().getPlaceSound();
            world.playSound(null, placementContext.getBlockPos(), sound, SoundCategory.BLOCKS, 1.0f, 1.0f);

            return ActionResult.SUCCESS;
        }

        return ActionResult.PASS;
    }

    /**
     * プレイヤーのインベントリをスキャンしてトーチを探すヘルパーメソッド
     * (この部分は変更ありません)
     */
    private int findTorchInInventory(PlayerInventory inventory) {
        for (int i = 0; i < inventory.main.size(); i++) {
            ItemStack stack = inventory.main.get(i);
            if (!stack.isEmpty() && stack.getItem() == Items.TORCH) {
                return i;
            }
        }
        return -1;
    }
}