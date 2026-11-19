-- Quem cadastrou o programa passa a ser opcional: excluir a conta da
-- universidade que cadastrou uma bolsa institucional (ou do administrador que
-- cadastrou um programa) era barrado pela FK com RESTRICT. O programa continua,
-- sem o autor, como já acontece com aprovado_por e avaliado_por.

-- DropForeignKey
ALTER TABLE `programa` DROP FOREIGN KEY `programa_id_usuario_fkey`;

-- AlterTable
ALTER TABLE `programa` MODIFY `id_usuario` INTEGER NULL;

-- AddForeignKey
ALTER TABLE `programa` ADD CONSTRAINT `programa_id_usuario_fkey` FOREIGN KEY (`id_usuario`) REFERENCES `usuario`(`id_usuario`) ON DELETE SET NULL ON UPDATE CASCADE;
