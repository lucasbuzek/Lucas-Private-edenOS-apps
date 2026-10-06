// HERMES scheduled trigger. Keep this small: schedule work, do not run an unbounded crawler here.
export default async () => {
  console.log(JSON.stringify({service:"HERMES", task:"scheduled-discovery-trigger", at:new Date().toISOString()}));
  return new Response(null, {status: 204});
};
export const config = { schedule: "0 */6 * * *" };
