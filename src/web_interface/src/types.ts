export type DataType = {
    points: number;
    initial_points: number;
    max_seconds_available: number;
    start_time: number;
    game_ended: boolean;
    won: string;
}

export type InitialDataType = {
    points: number;
    max_points: number;
}