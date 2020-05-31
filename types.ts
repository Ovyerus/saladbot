export interface ICheeseSettings {
  cheeseRole: string;
  cheeseChannel: string;
  lastCheeseSwap: number;
  canTransferCheese: boolean;
}

export interface IHealthSettings {
  healthChannel: string;
  lastHealthUpdate: number;
}

export interface ISaladSettings extends ICheeseSettings, IHealthSettings {}
