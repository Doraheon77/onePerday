import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();
  try {
    const guideColumns = await prisma.$queryRaw`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'nutrient_guide'
    `;
    console.log('Columns of nutrient_guide:', guideColumns);

    const standardColumns = await prisma.$queryRaw`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = 'nutrientStandards'
    `;
    console.log('Columns of nutrientStandards:', standardColumns);

  } catch (err) {
    console.error('Error querying columns:', err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
